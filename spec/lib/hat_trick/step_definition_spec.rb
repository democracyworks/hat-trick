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

  describe "#get_button" do
    it "returns the button(s) with the requested type" do
      step_definition.get_button(:next).should == { :label => 'Next', :default => true }
    end

    it "returns nil if no buttons of that type are found" do
      step_definition.get_button(:foo).should be_nil
    end

    it "works with custom button types" do
      custom_button = { :custom => { :label => "I'm a button!" } }
      default_buttons = step_definition.buttons
      step_definition.stubs(:buttons).returns(default_buttons + [custom_button])
      step_definition.get_button(:custom).should == custom_button[:custom]
    end
  end

  describe "#delete_button" do
    it "removes the button from the buttons array" do
      expect {
        step_definition.delete_button(:next)
      }.to change { step_definition.next_button }.from(
        { :label => 'Next', :default => true }
      ).to(nil)
    end
  end

  describe "#add_button" do
    it "replaces default if types match" do
      expect {
        step_definition.add_button(:next => {:label => 'Foo'})
      }.to change { step_definition.next_button }.from(
        { :label => 'Next', :default => true }
      ).to({ :label => 'Foo' })
    end

    it "doesn't replace non-default buttons" do
      expect {
        step_definition.add_button(:bar => {:label => 'Bar'})
      }.to change { step_definition.buttons.count }.from(2).to(3)
    end
  end

  describe "#buttons" do
    it "has exactly 2 buttons" do
      step_definition.buttons.should have(2).buttons
    end

    it "has a default next button" do
      step_definition.buttons.should include(
        { :next => { :label => "Next", :default => true } }
      )
    end

    it "has a default back button" do
      step_definition.buttons.should include(
        { :back => { :label => "Back", :default => true } }
      )
    end

    it "re-translates the labels every time it's called" do
      expect {
        I18n.stubs(:t).with("wizard.buttons.next",
                            {:default => "Next"}).returns("Foo")
      }.to change { step_definition.next_button[:label] }.from("Next").to("Foo")
    end

    it "uses configured button label" do
      mock_config.stubs(:next_button_label).returns("Click me!")
      step_definition.next_button[:label].should == "Click me!"
    end

    it "uses configured button label i18n key" do
      mock_config.stubs(:next_button_label_i18n_key).returns("wizard.buttons.foo_bar")
      I18n.stubs(:t).with("wizard.buttons.foo_bar").returns("FooBar")
      step_definition.next_button[:label].should == "FooBar"
    end
  end
end
