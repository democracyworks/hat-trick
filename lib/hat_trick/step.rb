require 'hat_trick/step_definition'

module HatTrick
  class Step
    attr_reader :step_def, :wizard
    attr_accessor :next_step
    attr_writer :skipped

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
      @skipped && !visited?
    end

    def visited?
      session["hat-trick.visited_steps"].include? self.to_sym
    end

    def mark_as_visited
      unless session.has_key?("hat-trick.visited_steps")
        session["hat-trick.visited_steps"] = []
      end
      session["hat-trick.visited_steps"] << self.to_sym
    end
  end
end
