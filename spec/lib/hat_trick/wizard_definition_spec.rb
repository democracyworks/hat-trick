require 'spec_helper'

describe HatTrick::WizardDefinition do
  let(:mock_config) {
    mock("HatTrick::Config").tap do |mc|
      mc.stubs(:next_button_label).returns(nil)
      mc.stubs(:back_button_label).returns(nil)
      mc.stubs(:next_button_label_i18n_key).returns(nil)
      mc.stubs(:back_button_label_i18n_key).returns(nil)
    end
  }

  subject(:wizard_definition) { HatTrick::WizardDefinition.new(mock_config) }

  it { should be_empty }

  describe "#add_step" do
    it "should accept a symbol for the step name" do
      step = wizard_definition.add_step(:step1)
      step.name.should == :step1
    end

    it "should add a step to the wizard def" do
      wizard_definition.add_step(:step1)
      wizard_definition.should have(1).step
    end

    it "should update the last_step attr" do
      step = wizard_definition.add_step(:step1)
      wizard_definition.last_step.should == step
    end
  end

  describe "#delete_step" do
    it "should remove the step from the wizard def" do
      step = wizard_definition.add_step(:goner)
      wizard_definition.delete_step(step)
      wizard_definition.steps.should_not include(step)
    end

    it "should update the the links between surrounding steps" do
    end
  end

  describe "#replace_step" do
  end

end
