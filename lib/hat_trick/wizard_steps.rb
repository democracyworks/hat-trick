module HatTrick
  class StepNotFound < StandardError; end

  module WizardSteps
    include Enumerable
    attr_reader :steps

    delegate :each, :empty?, :first, :last, :to => :steps

    alias_method :each_step, :each
    alias_method :to_ary, :steps
    alias_method :first_step, :first
    alias_method :last_step, :last

    def find_step(step)
      return nil if step.nil?
      if step.is_a?(HatTrick::Step) || step.is_a?(HatTrick::StepDefinition)
        find { |s| s.equal? step }
      else
        find { |s| s.name == step.to_sym }
      end
    end

    def step_after(_step)
      steps_after(_step).first
    end

    def steps_after(_step)
      step = find_step(_step)
      return [] unless step
      return [] if step.last? && !step.skipped?
      step_index = steps.index(step)
      max_index = steps.count - 1
      return [] if step_index >= max_index
      after_index = step_index + 1
      steps[after_index .. -1]
    end

    def step_before(_step)
      steps_before(_step).last
    end

    def steps_before(_step)
      step = find_step(_step)
      return [] unless step
      step_index = steps.index(step)
      return [] if step_index <= 0
      before_index = step_index - 1
      steps[0 .. before_index]
    end

    def add_step(step, args={})
      if step.is_a?(HatTrick::Step) || step.is_a?(HatTrick::StepDefinition)
        new_step = step
      else
        step_args = args.merge(:name => step, :wizard => self)
        new_step = HatTrick::StepDefinition.new(step_args)
      end

      if steps.count == 0
        new_step.first = true
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
      old_index = steps.index(old_step)
      raise ArgumentError, "Couldn't find step #{_old_step}" unless old_step
      new_step_in_wizard = find_step(_new_step)
      if new_step_in_wizard
        # new_step is already in the wizard
        return move_step(new_step_in_wizard, old_index)
      end

      if _new_step.is_a?(HatTrick::Step) || _new_step.is_a?(HatTrick::StepDefinition)
        new_step = _new_step
      else
        new_step = HatTrick::StepDefinition.new(:name => _new_step)
      end

      steps.delete_at(old_index)
      steps.insert(old_index, new_step)
      new_step
    end

    def move_step(step, index)
      raise ArgumentError, "#{step} isn't in this wizard" unless steps.include?(step)
      current_index = steps.index(step)
      unless index < current_index
        raise ArgumentError, "#{step} has index #{current_index}; must be >= #{index}"
      end

      while steps.index(step) > index
        steps.delete_at(index)
      end
    end
  end
end
