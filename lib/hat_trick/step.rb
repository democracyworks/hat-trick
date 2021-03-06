require 'hat_trick/step_definition'

module HatTrick
  class Step
    attr_reader :step_def, :wizard, :buttons
    attr_accessor :next_step, :redirect_from
    attr_writer :skipped

    delegate :name, :fieldset, :to_sym, :to_s, :run_after_callback,
             :run_before_callback, :include_data,
             :run_include_data_callback, :run_step_contents_callback,
             :include_data_key, :config, :step_contents, :last?, :first?,
             :to => :step_def

    delegate :visited_steps, :skipped_steps, :to => :wizard

    def initialize(step_def, wizard)
      @step_def = step_def
      @buttons = step_def.buttons.dup
      @wizard = wizard
      @skipped = step_def.skipped?
    end

    def add_button(button)
      @buttons.delete_if do |b|
        b.keys.first == button.keys.first && b[b.keys.first][:default]
      end
      @buttons << button
    end

    def delete_button(type)
      @buttons.delete_if { |b| b.keys.first == type }
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

    def render_buttons(buttons)
      buttons.map do |b|
        button_type = b.keys.first
        button = b[button_type]
        if button[:label].respond_to?(:call)
          rendered_label = button[:label].call
          { button_type => button.merge({label: rendered_label}) }
        else
          b
        end
      end
    end

    def as_json(options = nil)
      json = { :name => name, :fieldset => fieldset }
      json[:buttons] = buttons.empty? ? [] : render_buttons(buttons)
      json[:first] = first?
      json[:redirect] = redirect?
      json[:redirectFrom] = redirect_from
      json
    end
  end
end
