require 'spec_helper'

describe HatTrick::StepDefinition do
  let(:mock_config) {
    mock("HatTrick::Config").tap do |mc|
      mc.stubs(:next_button_label).returns(nil)
      mc.stubs(:back_button_label).returns(nil)
      mc.stubs(:next_button_label_i18n_key).returns(nil)
      mc.stubs(:back_button_label_i18n_key).returns(nil)
    end
  }

  let(:mock_wizard) {
    mock("HatTrick::WizardDefinition").tap do |mw|
      mw.stubs(:config).returns(mock_config)
    end
  }

  subject(:step_definition) {
    HatTrick::StepDefinition.new(:wizard => mock_wizard)
  }

  before :each do
    I18n.stubs(:t).with("wizard.buttons.next", :default => "Next").returns("Next")
    I18n.stubs(:t).with("wizard.buttons.back", :default => "Back").returns("Back")
  end

  describe "#buttons" do
    it "has exactly 2 buttons" do
      step_definition.buttons.should have(2).buttons
    end

    it "has a default next button" do
      step_definition.buttons.should include(
        { :next => { :label => "Next", :type => :next, :default => true } }
      )
    end

    it "has a default back button" do
      step_definition.buttons.should include(
        { :back => { :label => "Back", :type => :back, :default => true } }
      )
    end

    it "re-translates the labels every time it's called" do
      expect {
        I18n.stubs(:t).with("wizard.buttons.next",
                            {:default => "Next"}).returns("Foo")
      }.to change {
        step_definition.buttons.first[:next][:label]
      }.from("Next").to("Foo")
    end

    it "uses configured button label" do
      mock_config.stubs(:next_button_label).returns("Click me!")
      step_definition.buttons.first[:next][:label].should == "Click me!"
    end

    it "uses configured button label i18n key" do
      mock_config.stubs(:next_button_label_i18n_key).returns("wizard.buttons.foo_bar")
      I18n.stubs(:t).with("wizard.buttons.foo_bar").returns("FooBar")
      step_definition.buttons.first[:next][:label].should == "FooBar"
    end
  end
end
