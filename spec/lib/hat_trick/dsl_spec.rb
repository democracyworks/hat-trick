require 'spec_helper'

# will automatically get HatTrick::DSL included
class FakeController < ActionController::Base; end

describe HatTrick::DSL do
  let(:controller_class) { FakeController }

  # save some typing
  def dsl(&block)
    controller_class.instance_eval &block
  end
  
  describe HatTrick::DSL::ClassMethods do
    describe "#step" do
      it "should call Wizard#add_step" do
        HatTrick::WizardDefinition.any_instance.expects(:add_step).with(:foo, {})
        dsl do
          wizard do
            step :foo
          end
        end
      end
    end
  end
end
