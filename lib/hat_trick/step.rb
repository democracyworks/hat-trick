require 'hat_trick/step_definition'

module HatTrick
  class Step
    attr_reader :step_def, :wizard
    attr_accessor :next_step
    attr_writer :skipped

    delegate :name, :fieldset, :buttons, :to_sym, :to_s, :as_json,
             :run_after_callback, :run_before_callback, :include_data,
             :run_include_data_callback, :include_data_key, :config,
             :last?, :to => :step_def

    delegate :visited_steps, :skipped_steps, :to => :wizard

    def initialize(step_def, wizard)
      @step_def = step_def
      @wizard = wizard
      @skipped = step_def.skipped?
    end

    def session
      wizard.session
    end

    def skipped?
      (@skipped || skipped_steps.include?(self.to_sym)) && !visited?
    end

    def visited?
      visited_steps.include? self.to_sym
    end

    def mark_as_visited
      visited_steps << self.to_sym
    end
  end
end
