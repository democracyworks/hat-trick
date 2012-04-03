require 'hat_trick/step'
require 'hat_trick/wizard'

module HatTrick
  class WizardDefinition
    include Enumerable
    attr_reader :steps

    delegate :each, :empty?, :first, :last, :to => :steps

    alias_method :each_step, :each
    alias_method :to_ary, :steps
    alias_method :first_step, :first
    alias_method :last_step, :last

    def initialize
      @steps = []
    end

    def add_step(step, args={})
      if step.is_a?(HatTrick::Step)
        new_step = step
      else
        step_args = args.merge(:name => step)
        new_step = Step.new(step_args)
      end

      steps << new_step

      new_step
    end

    def delete_step(_step)
      step = find_step(_step)
      steps.delete(step)
    end

    def replace_step(_old_step, _new_step)
      old_step = find_step(_old_step)
      raise ArgumentError, "Couldn't find step #{_old_step}" unless old_step
      if _new_step.is_a?(HatTrick::Step)
        new_step = _new_step
      else
        new_step = Step.new(:name => _new_step)
      end

      old_index = steps.index(old_step)
      steps.delete_at(old_index)
      steps.insert(old_index, new_step)
      new_step
    end

    def find_step(step)
      if step.is_a?(HatTrick::Step)
        find { |s| s.equal? step }
      else
        find { |s| s.name == step.to_sym }
      end
    end

    def step_after(_step)
      step = find_step(_step)
      after_index = steps.index(step) + 1
      steps[after_index]
    end

    def step_before(_step)
      step = find_step(_step)
      before_index = steps.index(step) - 1
      steps[before_index]
    end

    def get_wizard(controller)
      wizard = HatTrick::Wizard.new(self)
      wizard.controller = controller
      wizard.alias_action_methods!
      wizard
    end
  end
end
