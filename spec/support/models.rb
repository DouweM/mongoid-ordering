class DummyParentDocument
  include Mongoid::Document
  include Mongoid::Ordering
  
  ordered scope: nil
  
  has_many :children, class_name: "DummyChildDocument",
                      inverse_of: :parent,
                      dependent:  :destroy
end

class DummyChildDocument
  include Mongoid::Document
  include Mongoid::Ordering
  
  ordered scope: :parent
  
  belongs_to :parent, class_name: "DummyParentDocument",
                      inverse_of: :children
end