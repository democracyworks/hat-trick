require 'spec_helper'

describe HatTrick::WizardDefinition do
  subject { HatTrick::WizardDefinition.new }

  it { should be_empty }

  describe "#add_step" do
    it "should accept a symbol for the step name" do
      step = subject.add_step(:step1)
      step.name.should == :step1
    end

    it "should add a step to the wizard def" do
      subject.add_step(:step1)
      subject.should have(1).step
    end

    it "should update the last_step attr" do
      step = subject.add_step(:step1)
      subject.last_step.should == step
    end
  end

  describe "#delete_step" do
    it "should remove the step from the wizard def" do
      step = subject.add_step(:goner)
      subject.delete_step(step)
      subject.steps.should_not include(step)
    end

    it "should update the the links between surrounding steps" do
    end
  end

  describe "#replace_step" do
  end

end
