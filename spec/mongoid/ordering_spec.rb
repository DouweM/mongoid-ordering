require "spec_helper.rb"

describe Mongoid::Ordering do
  
  describe ".ordered" do
    
    let(:test_class) {
      Class.new do
        include Mongoid::Document
        include Mongoid::Ordering
        
        ordered scope: [:main, :fallback]
      end
    }
    
    it "sets the default sibling scope and the ordering scopes to the specified scope" do
      test_class.default_sibling_scope.should eq([:main, :fallback])
      test_class.ordering_scopes.should       eq([:main, :fallback])
    end
  end
  
  describe "Instance methods" do
  
    let!(:sibling1) { DummyParentDocument.create }  
    let!(:sibling2) { DummyParentDocument.create }  
    let!(:sibling3) { DummyParentDocument.create }
  
    describe "#lower_siblings" do
    
      it "returns the siblings with a higher position" do
        sibling1.lower_siblings.should eq([sibling2, sibling3])
      end
    end
  
    describe "#higher_siblings" do
    
      it "returns the siblings with a lower position" do
        sibling3.higher_siblings.should eq([sibling1, sibling2])
      end
    end
  
    describe "#highest_sibling" do
    
      it "returns the first sibling" do
        sibling2.highest_sibling.should eq(sibling1)
      end
    end
  
    describe "#lowest_sibling" do
    
      it "returns the last sibling" do
        sibling2.lowest_sibling.should eq(sibling3)
      end
    end
  
    describe "#at_top?" do
    
      context "when the subject is the first sibling" do
      
        it "returns true" do
          sibling1.should be_at_top
        end
      end
    
      context "when the subject is not the first sibling" do
      
        it "returns false" do
          sibling2.should_not be_at_top
        end
      end
    end
  
    describe "#at_bottom?" do
    
      context "when the subject is the last sibling" do
      
        it "returns true" do
          sibling3.should be_at_bottom
        end
      end
    
      context "when the subject is not the last sibling" do
      
        it "returns false" do
          sibling2.should_not be_at_bottom
        end
      end
    end
  
    describe "#move_to_top" do
    
      it "rearranges the siblings" do
        sibling3.move_to_top
      
        sibling3.siblings_and_self.should eq([sibling3, sibling1, sibling2])
      end
    
      it "properly sets the positions" do
        sibling3.move_to_top
      
        sibling3.reload.position.should eq(0)
        sibling1.reload.position.should eq(1)
        sibling2.reload.position.should eq(2)
      end
    end
  
    describe "#move_to_bottom" do
    
      it "rearranges the siblings" do
        sibling1.move_to_bottom
      
        sibling1.siblings_and_self.should eq([sibling2, sibling3, sibling1])
      end
    
      it "properly sets the positions" do
        sibling1.move_to_bottom
      
        sibling2.reload.position.should eq(0)
        sibling3.reload.position.should eq(1)
        sibling1.reload.position.should eq(2)
      end
    end
  
    describe "#move_up" do
    
      it "rearranges the siblings" do
        sibling3.move_up
      
        sibling3.siblings_and_self.should eq([sibling1, sibling3, sibling2])
      end
    
      it "properly sets the positions" do
        sibling3.move_up
      
        sibling1.reload.position.should eq(0)
        sibling3.reload.position.should eq(1)
        sibling2.reload.position.should eq(2)
      end
    end
  
    describe "#move_down" do
    
      it "rearranges the siblings" do
        sibling1.move_down
      
        sibling1.siblings_and_self.should eq([sibling2, sibling1, sibling3])
      end
    
      it "properly sets the positions" do
        sibling1.move_down
      
        sibling2.reload.position.should eq(0)
        sibling1.reload.position.should eq(1)
        sibling3.reload.position.should eq(2)
      end
    end
  
    describe "#move_above" do
    
      context "when the subject was somewhere above the other object" do

        it "rearranges the siblings" do
          sibling1.move_above(sibling3)

          sibling1.siblings_and_self.should eq([sibling2, sibling1, sibling3])
        end

        it "properly sets the positions" do
          sibling1.move_above(sibling3)

          sibling2.reload.position.should eq(0)
          sibling1.reload.position.should eq(1)
          sibling3.reload.position.should eq(2)
        end
      end
    
      context "when the subject was somewhere below the other object" do

        it "rearranges the siblings" do
          sibling3.move_above(sibling2)

          sibling3.siblings_and_self.should eq([sibling1, sibling3, sibling2])
        end

        it "properly sets the positions" do
          sibling3.move_above(sibling2)

          sibling1.reload.position.should eq(0)
          sibling3.reload.position.should eq(1)
          sibling2.reload.position.should eq(2)
        end
      end
    end
  
    describe "#move_below" do
    
      context "when the subject was somewhere above the other object" do

        it "rearranges the siblings" do
          sibling1.move_below(sibling2)

          sibling1.siblings_and_self.should eq([sibling2, sibling1, sibling3])
        end

        it "properly sets the positions" do
          sibling1.move_below(sibling2)

          sibling2.reload.position.should eq(0)
          sibling1.reload.position.should eq(1)
          sibling3.reload.position.should eq(2)
        end
      end
    end
    
    context "when the subject was somewhere below the other object" do

      it "rearranges the siblings" do
        sibling3.move_below(sibling1)

        sibling3.siblings_and_self.should eq([sibling1, sibling3, sibling2])
      end

      it "properly sets the positions" do
        sibling3.move_below(sibling1)

        sibling1.reload.position.should eq(0)
        sibling3.reload.position.should eq(1)
        sibling2.reload.position.should eq(2)
      end
    end
  end
  
  describe "creating a document" do
    
    context "when no siblings exist yet" do
      
      it "sets the subject's position to 0" do
        DummyParentDocument.create.position.should eq(0)
      end
    end
    
    context "when a sibling already exist" do
      
      let!(:sibling) { DummyParentDocument.create }  
      
      it "sets the subject's position to the highest position plus 1" do
        DummyParentDocument.create.position.should eq(1)
      end
    end
  end
  
  describe "moving a document to another parent" do
    
    let!(:parent1)        { DummyParentDocument.create }
    let!(:parent1_child1) { DummyChildDocument.create(parent: parent1) }
    let!(:parent1_child2) { DummyChildDocument.create(parent: parent1) }
    let!(:parent1_child3) { DummyChildDocument.create(parent: parent1) }
    let!(:parent2)        { DummyParentDocument.create }
    let!(:parent2_child1) { DummyChildDocument.create(parent: parent2) }
    let!(:parent2_child2) { DummyChildDocument.create(parent: parent2) }
    let!(:parent2_child3) { DummyChildDocument.create(parent: parent2) }
    
    before(:each) do
      parent1_child2.parent = parent2
      parent1_child2.save
    end
    
    it "moves lower siblings up" do
      parent1_child1.reload.position.should eq(0)
      parent1_child3.reload.position.should eq(1)
    end
    
    it "sets the subject's position to the highest position under the new parent plus 1" do
      parent1_child2.reload.position.should eq(3)
    end
  end
  
  describe "destroying a document" do
  
    let!(:sibling1) { DummyParentDocument.create }  
    let!(:sibling2) { DummyParentDocument.create }  
    let!(:sibling3) { DummyParentDocument.create }
    
    it "moves lower siblings up" do
      sibling2.destroy
      
      sibling1.reload.position.should eq(0)
      sibling3.reload.position.should eq(1)
    end
  end
end