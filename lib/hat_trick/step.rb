require 'hat_trick/step_definition'

module HatTrick
  class Step
    attr_reader :step_def, :wizard
    attr_writer :skipped
    attr_accessor :next_step

    delegate :name, :fieldset, :buttons, :repeat_of, :to_sym, :to_s, :as_json,
             :run_after_callback, :run_before_callback, :repeat?,
             :run_include_data_callback, :include_data_key, :to => :step_def

    def initialize(step_def, wizard)
      @step_def = step_def
      @wizard = wizard
      @skipped = step_def.skipped?
    end

    def session
      wizard.session
    end

    def skipped?
      not visited? and @skipped
    end

    def visited?
      session["hat-trick.steps_visited"].include? self.to_sym
    end

    def visited=(_visited)
      session["hat-trick.steps_visited"] << self.to_sym
    end
  end
end
