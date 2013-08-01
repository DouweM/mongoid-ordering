require "mongoid/siblings"

module Mongoid

  # Add 'position' field, multiple methods and multiple callbacks to help with 
  # ordering your documents.
  module Ordering
    extend ActiveSupport::Concern
    include Mongoid::Siblings
    
    included do
      cattr_accessor :ordering_scopes
      self.ordering_scopes = []
      
      field :position, type: Integer

      index position: 1

      default_scope asc(:position)

      before_save :assign_default_position
      before_save :reposition_former_siblings, if: :sibling_reposition_required?
      after_destroy :move_lower_siblings_up
    end
    
    module ClassMethods
      # Sets options used for ordering.
      #
      # @example Set options.
      #   class Book
      #     include Mongoid::Document
      #     include Mongoid::Ordering
      #   
      #     belongs_to :author
      #   
      #     ordered scope: :author
      #   end
      #
      # @param [ Hash ] options The options.
      #
      # @option options [ Array<Symbol>, Symbol ] scope One or more relations or
      #   attributes that will determine the scope within which to keep the
      #   documents in order.
      def ordered(options = {})
        self.default_sibling_scope = self.ordering_scopes = Array.wrap(options[:scope]).compact
      end
    end

    # Returns siblings positioned above this document.
    # Siblings with a position lower than this document's position.
    #
    # @example Retrieve siblings positioned above this document.
    #   book.higher_siblings
    #
    # @return [ Mongoid::Criteria ] Criteria to retrieve the document's higher siblings.
    def higher_siblings
      self.siblings.where(:position.lt => self.position)
    end

    # Returns siblings positioned below this document.
    # Siblings with a position greater than this document's position.
    #
    # @example Retrieve siblings positioned below this document.
    #   book.lower_siblings
    #
    # @return [ Mongoid::Criteria ] Criteria to retrieve the document's lower siblings.
    def lower_siblings
      self.siblings.where(:position.gt => self.position)
    end

    # Returns the highest sibling (could be self).
    #
    # @example Retrieve the highest sibling.
    #   book.highest_sibling
    #
    # @return [ Mongoid::Document ] The highest sibling.
    def highest_sibling
      self.siblings_and_self.first
    end

    # Returns the lowest sibling (could be self).
    #
    # @example Retrieve the lowest sibling.
    #   book.lowest_sibling
    #
    # @return [ Mongoid::Document ] The lowest sibling
    def lowest_sibling
      self.siblings_and_self.last
    end

    # Is this the highest sibling?
    #
    # @example Is this the highest sibling?
    #   book.at_top?
    #
    # @return [ Boolean ] True if this document is the highest sibling.
    def at_top?
      self.higher_siblings.empty?
    end

    # Is this the lowest sibling?
    #
    # @example Is this the lowest sibling?
    #   book.at_bottom?
    #
    # @return [ Boolean ] True if this document is the lowest sibling.
    def at_bottom?
      self.lower_siblings.empty?
    end

    # Moves this document above all of its siblings.
    #
    # @example Move document to the top.
    #   book.move_to_top
    #
    # @return [ Boolean ] True if the document was moved to the top or was 
    #   already there.
    def move_to_top
      return true if at_top?
      self.move_above(self.highest_sibling)
    end

    # Moves this document below all of its siblings.
    #
    # @example Move document to the bottom.
    #   book.move_to_bottom
    #
    # @return [ Boolean ] True if the document was moved to the bottom or was 
    #   already there.
    def move_to_bottom
      return true if at_bottom?
      self.move_below(self.lowest_sibling)
    end

    # Moves this document one position up.
    #
    # @example Move document one position up.
    #   book.move_up
    def move_up
      return if at_top?
      self.siblings.where(position: self.position - 1).first.inc(:position, 1)
      self.inc(:position, -1)
    end

    # Moves this document one position down.
    #
    # @example Move document one position down.
    #   book.move_down
    def move_down
      return if at_bottom?
      self.siblings.where(position: self.position + 1).first.inc(:position, -1)
      self.inc(:position, 1)
    end

    # Moves this document above the specified document.
    #
    # This method changes this document's scope values if necessary.
    #
    # @example Move document above another document.
    #   book.move_above(other_book)
    #
    # @param [ Mongoid::Document ] other The document to Moves this document 
    #   above.
    def move_above(other)
      return false unless self.sibling_of!(other)

      if self.position > other.position
        new_position = other.position
        other.lower_siblings.and(:position.lt => self.position).each { |s| s.inc(:position, 1) }
        other.inc(:position, 1)
      else
        new_position = other.position - 1
        other.higher_siblings.and(:position.gt => self.position).each { |s| s.inc(:position, -1) }
      end
      self.position = new_position

      self.save!
    end

    # Moves this document below the specified document.
    #
    # This method changes this document's scope values if necessary.
    #
    # @example Move document below another document.
    #   book.move_below(other_book)
    #
    # @param [ Mongoid::Document ] other The document to Moves this document 
    #   below.
    def move_below(other)
      return false unless self.sibling_of!(other)

      if self.position > other.position
        new_position = other.position + 1
        other.lower_siblings.and(:position.lt => self.position).each { |s| s.inc(:position, 1) }
      else
        new_position = other.position
        other.higher_siblings.and(:position.gt => self.position).each { |s| s.inc(:position, -1) }
        other.inc(:position, -1)
      end
      self.position = new_position

      self.save!
    end

    private  

      def move_lower_siblings_up
        return if self.ordering_scopes.any? do |scope|
          scope_metadata = self.reflect_on_association(scope)
          next if scope_metadata.nil?

          relation = send(scope_metadata.name)
          next if relation.nil?

          relation.flagged_for_destroy? && scope_metadata.inverse_metadata(relation).destructive?
        end

        self.lower_siblings.each { |s| s.inc(:position, -1) }
      end

      def sibling_reposition_required?
        return false if self.ordering_scopes.empty?
        self.ordering_scopes.any? { |scope| attribute_changed?(key_for_scope(scope)) } && persisted?
      end

      def reposition_former_siblings
        return if self.ordering_scopes.empty?
        
        old_scope_values = {}
        self.ordering_scopes.each do |scope|
          scope_metadata = self.reflect_on_association(scope)
          scope_key = scope_metadata ? scope_metadata.key : scope.to_s
          
          if attribute_changed?(scope_key)
            old_value = attribute_was(scope_key)

            old_scope_values[scope] = if scope_metadata && old_value
              model = scope_metadata.inverse_type ? attribute_was(scope_metadata.inverse_type) : scope_metadata.klass
              scope_metadata.criteria(old_value, model).first
            else
              old_value
            end
          end
        end
        
        former_siblings = self.siblings(scope_values: old_scope_values).where(:position.gt => (attribute_was("position") || 0))
        former_siblings.each { |s| s.inc(:position,  -1) }
      end

      def assign_default_position
        return unless self.position.nil? ||
                      (self.ordering_scopes.any? { |scope| attribute_changed?(key_for_scope(scope)) } &&
                       !new_record?)

        siblings = self.siblings
        self.position = if siblings.empty? || siblings.map(&:position).compact.empty?
          0
        else
          siblings.max(:position).to_i + 1
        end
      end

      def key_for_scope(scope)
        return nil if scope.nil?
        metadata = self.reflect_on_association(scope)
        metadata ? metadata.key : scope.to_s
      end
  end
end