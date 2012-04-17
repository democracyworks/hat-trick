require 'hat_trick/step_definition'

module HatTrick
  class Step
    attr_reader :step_def
    attr_writer :skipped, :visited
    attr_accessor :next_step

    delegate :name, :fieldset, :buttons, :repeat_of, :to_sym, :to_s, :as_json,
             :run_after_callback, :run_before_callback, :repeat?,
             :run_include_data_callback, :include_data_key, :to => :step_def

    def initialize(step_def)
      @step_def = step_def
      @visited = false
      @skipped = step_def.skipped?
    end

    def skipped?
      @skipped
    end

    def visited?
      @visited
    end
  end
end
