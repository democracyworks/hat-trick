require 'spec_helper'

describe HatTrick::Step do
  subject { HatTrick::Step.new(name: "test_step") }

  let(:wizard_def) { HatTrick::WizardDefinition.new }

  it { should be_a(HatTrick::Step) }
end
