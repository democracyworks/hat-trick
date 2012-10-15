require 'spec_helper'

describe HatTrick::Wizard do
  let(:mock_config) {
    mock("HatTrick::Config").tap do |mc|
      mc.stubs(:next_button_label).returns(nil)
      mc.stubs(:back_button_label).returns(nil)
      mc.stubs(:next_button_label_i18n_key).returns(nil)
      mc.stubs(:back_button_label_i18n_key).returns(nil)
    end
  }

  let(:wizard_definition) {
    HatTrick::WizardDefinition.new(mock_config).tap do |wiz_def|
      wiz_def.add_step(:step1)
      wiz_def.add_step(:step2)
      wiz_def.add_step(:step3)
      wiz_def.add_step(:step4)
      wiz_def.add_step(:step5)
    end
  }

  subject(:wizard) {
    HatTrick::Wizard.new(wizard_definition)
  }

  before :each do
    wizard.start
  end

  describe "advancing steps" do
    it "should go from step1 to step2" do
      wizard.current_step.to_sym.should == :step1
      wizard.advance_step
      wizard.current_step.to_sym.should == :step2
    end
  end

  describe "skipping steps" do
    it "should skip step2 when requested" do
      wizard.skip_step :step2
      wizard.advance_step
      wizard.current_step.to_sym.should == :step3
    end

    it "should skip steps 2 & 3 when requested" do
      wizard.skip_step :step2
      wizard.skip_step :step3
      wizard.advance_step
      wizard.current_step.to_sym.should == :step4
    end
  end

  describe "setting explicit next steps" do
    it "should advance to the requested next step when one is set" do
      wizard.steps.first.next_step = :step4
      wizard.advance_step
      wizard.current_step.to_sym.should == :step4
    end
  end

  describe "#previously_visited_step" do
    it "should return the most recently visited step" do
      wizard.steps[0].mark_as_visited
      wizard.steps[1].mark_as_visited
      wizard.steps[3].mark_as_visited
      wizard.current_step = :step5
      wizard.previously_visited_step.to_sym.should == :step4
    end
  end
end
