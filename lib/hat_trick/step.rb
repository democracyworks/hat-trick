require 'hat_trick/step_definition'

module HatTrick
  class Step
    attr_reader :step_def, :wizard
    attr_accessor :next_step, :redirect_from
    attr_writer :skipped

    delegate :name, :fieldset, :add_button, :delete_button, :buttons, :to_sym,
             :to_s, :run_after_callback, :run_before_callback, :include_data,
             :run_include_data_callback, :run_step_contents_callback,
             :include_data_key, :config, :step_contents, :last?, :first?,
             :to => :step_def

    delegate :visited_steps, :skipped_steps, :to => :wizard

    def initialize(step_def, wizard)
      @step_def = step_def
      @wizard = wizard
      @skipped = step_def.skipped?
    end

    def skipped?
      @skipped || (skipped_steps.include?(self.to_sym) && !visited?)
    end

    def redirect?
      redirect_from.present?
    end

    def visited?
      visited_steps.include? self.to_sym
    end

    def mark_as_visited
      visited_steps << self.to_sym
    end

    def as_json(options = nil)
      json = { :name => name, :fieldset => fieldset }
      json[:buttons] = buttons.empty? ? [] : buttons
      json[:first] = first?
      json[:redirect] = redirect?
      json[:redirectFrom] = redirect_from
      json
    end
  end
end
