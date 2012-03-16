require 'spec_helper'

describe HatTrick::Step do
  describe "#before?" do
    let(:wizard) { HatTrick::Wizard.new }

    before :each do
      @step1 = wizard.add_step(:step1)
      @step2 = wizard.add_step(:step2)
      @step3 = wizard.add_step(:step3)
    end

    it "should return true when arg is before self in the wizard" do
      @step1.should be_before @step3
    end

    it "should return false when arg is after self in the wizard" do
      @step2.should_not be_before @step1
    end

    it "should return false when steps aren't in the same wizard" do
      random_step = HatTrick::Step.new
      @step1.should_not be_before random_step
    end
  end

  describe "#after?" do
    let(:wizard) { HatTrick::Wizard.new }

    before :each do
      @step1 = wizard.add_step(:step1)
      @step2 = wizard.add_step(:step2)
      @step3 = wizard.add_step(:step3)
    end

    it "should return true when arg is after self in the wizard" do
      @step3.should be_after @step1
    end

    it "should return false when arg is before self in the wizard" do
      @step2.should_not be_after @step3
    end

    it "should return false when steps aren't in the same wizard" do
      random_step = HatTrick::Step.new
      @step1.should_not be_after random_step
    end
  end
end
