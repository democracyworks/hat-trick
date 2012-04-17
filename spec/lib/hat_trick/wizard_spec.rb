require 'spec_helper'

describe HatTrick::Wizard do
  subject {
    wiz_def = HatTrick::WizardDefinition.new
    wiz_def.add_step(:step1)
    wiz_def.add_step(:step2)
    wiz_def.add_step(:step3)
    wiz_def.add_step(:step4)
    wiz_def.add_step(:step5)

    HatTrick::Wizard.new(wiz_def)
  }

  before :each do
    subject.start
  end

  describe "advancing steps" do
    it "should go from step1 to step2" do
      subject.current_step.to_sym.should == :step1
      subject.advance_step
      subject.current_step.to_sym.should == :step2
    end
  end

  describe "skipping steps" do
    it "should skip step2 when requested" do
      subject.skip_step :step2
      subject.advance_step
      subject.current_step.to_sym.should == :step3
    end

    it "should skip steps 2 & 3 when requested" do
      subject.skip_step :step2
      subject.skip_step :step3
      subject.advance_step
      subject.current_step.to_sym.should == :step4
    end
  end

  describe "repeating steps" do
    it "should repeat step 2 when requested" do
    end
  end

  describe "setting explicit next steps" do
    it "should advance to the requested next step when one is set" do
      subject.steps.first.next_step = :step4
      subject.advance_step
      subject.current_step.to_sym.should == :step4
    end
  end

  describe "#previously_visited_step" do
    it "should return the most recently visited step" do
      subject.steps[0].visited = true
      subject.steps[1].visited = true
      subject.steps[3].visited = true
      subject.current_step = :step5
      subject.previously_visited_step.to_sym.should == :step4
    end
  end
end
