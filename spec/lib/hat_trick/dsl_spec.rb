require 'spec_helper'

describe HatTrick::DSL do
  subject(:controller) {
    Class.new.send(:include, HatTrick::DSL).tap do |c|
      c.stubs(:before_filter)
      c.any_instance.stubs(:render)
    end
  }

  describe HatTrick::DSL::ClassMethods do
    describe "#step" do
      it "should call Wizard#add_step" do
        HatTrick::WizardDefinition.any_instance.expects(:add_step).with(:foo, {})
        controller.instance_eval do
          wizard do
            step :foo
          end
        end
      end

      it "raises an error if called outside a wizard block" do
        expect { controller.step :foo }.to raise_error
      end
    end
  end
end
