require 'hat_trick/wizard_definition'
require 'hat_trick/controller_hooks'
require 'hat_trick/config'

module HatTrick
  module DSL
    extend ActiveSupport::Concern

    attr_accessor :hat_trick_wizard

    delegate :model, :previously_visited_step, :to => :hat_trick_wizard

    def next_step(name=nil)
      if name.nil?
        # getter
        hat_trick_wizard.next_step
      else
        # setter
        step = hat_trick_wizard.find_step(name)
        # explicitly set steps should not be skipped
        step.skipped = false
        hat_trick_wizard.current_step.next_step = step
      end
    end

    def previously_visited_step_name
      if previously_visited_step.nil?
        ''
      else
        previously_visited_step.name
      end
    end

    def skip_this_step
      hat_trick_wizard.skip_step(hat_trick_wizard.current_step)
    end

    def button_to(step_name, options={})
      button = self.class.send(:create_button_to, step_name, options)
      hat_trick_wizard.current_step.add_button button
    end

    def hide_button(button_type)
      hat_trick_wizard.current_step.delete_button button_type
    end

    def remaining_step_count
      hat_trick_wizard.steps_after_current
    end

    def adjust_remaining_step_count_by(diff)
      hat_trick_wizard.steps_remaining += diff
    end

    def change_remaining_step_count_to(count)
      hat_trick_wizard.steps_remaining = count
    end

    def total_step_count
      hat_trick_wizard.total_step_count
    end

    def reset_step_count
      hat_trick_wizard.override_step_count = nil
    end

    def redirect_to_step(step_name)
      hat_trick_wizard.redirect_to_step step_name
    end

    def redirect_to_external_url(url)
      hat_trick_wizard.external_redirect_url = url
    end

    module ClassMethods
      attr_reader :wizard_def

      def wizard(&block)
        if block_given?
          include HatTrick::DSL::ControllerInstanceMethods
          include HatTrick::ControllerHooks

          config = HatTrick::Config.new
          @wizard_def = HatTrick::WizardDefinition.new(config)

          yield

        else
          raise ArgumentError, "wizard called without a block"
        end
      end

      def configure(&block)
        raise "Must pass a block to configure" unless block_given?
        self.configure_callback = block
      end

      def model_class(klass)
        klass.send(:include, HatTrick::ModelMethods)
      end

      def button_label(type, label)
        wizard_def.config.send("#{type}_button_label=", label)
      end

      def button_label_i18n_key(type, i18n_key)
        wizard_def.config.send("#{type}_button_label_i18n_key=", i18n_key)
      end

      def step(name, args={}, &block)
        raise "step must be called from within a wizard block" unless wizard_def
        wizard_def.add_step(name, args)
        instance_eval &block if block_given?
      end

      def skip_this_step
        # skip_this_step in wizard definition (class) context means the step
        # can be explicitly jumped to, but won't be visited in the normal flow
        raise "skip_this_step must be called from within a wizard block" unless wizard_def
        wizard_def.last_step.skipped = true
      end

      def last_step
        raise "skip_this_step must be called from within a wizard block" unless wizard_def
        wizard_def.last_step.last = true
      end

      def button_to(step_name, options={})
        raise "button_to must be called from within a wizard block" unless wizard_def
        wizard_def.last_step.add_button create_button_to(step_name, options)
      end

      def hide_button(button_type)
        raise "before must be called from within a wizard block" unless wizard_def
        step = wizard_def.last_step
        step.delete_button button_type
      end

      def before(scope=:current_step, &block)
        raise "before must be called from within a wizard block" unless wizard_def
        if scope == :each
          wizard_def.before_callback_for_all_steps = block
        else
          wizard_def.last_step.before_callback = block
        end
      end

      def after(scope=:current_step, &block)
        raise "after must be called from within a wizard block" unless wizard_def
        if scope == :each
          wizard_def.after_callback_for_all_steps = block
        else
          wizard_def.last_step.after_callback = block
        end
      end

      def include_data(key, &block)
        raise "include_data must be called from within a wizard block" unless wizard_def
        wizard_def.last_step.include_data = { key.to_sym => block }
      end

      def set_contents(&block)
        raise "set_contents must be called from within a wizard block" unless wizard_def
        wizard_def.last_step.step_contents_callback = block
      end

      private

      def configure_callback
        @configure_callback
      end

      def configure_callback=(block)
        @configure_callback = block
      end

      def create_button_to(to_step_name, options={})
        label = options[:label]
        label ||= to_step_name.to_s.humanize

        name = options[:name]
        name ||= to_step_name.to_s.parameterize

        value = options[:value]
        value ||= to_step_name.to_s.parameterize

        if options
          id = options[:id]
          css_class = options[:class]
        end

        button = { :name => name, :value => value, :label => label }
        button[:id] = id unless id.nil?
        button[:class] = css_class unless css_class.nil?

        { to_step_name => button }
      end
    end

    module ControllerInstanceMethods
      extend ActiveSupport::Concern

      included do
        before_filter :setup_wizard
      end

      def back_to_start
        respond_to do |format|
          format.json { }
        end
      end

      private

      def setup_wizard
        wizard_def = self.class.instance_variable_get("@wizard_def")
        @hat_trick_wizard ||= wizard_def.make_wizard_for(self)

        config_callback = self.class.send(:configure_callback)
        if config_callback.is_a?(Proc)
          instance_exec(wizard_def.config, &config_callback)
        end

        if params.has_key?('_ht_meta')
          step_name = params['_ht_meta']['step']
        end

        # TODO: Setup the route that enables this in hat-trick automatically.
        #       Currently done manually in the app.
        if params.has_key?('step')
          step_name = params['step']
        end

        if step_name.present?
          Rails.logger.debug "Setting current step to: #{step_name}"
          begin
            @hat_trick_wizard.current_step = step_name
          rescue StepNotFound => e
            raise ActionController::RoutingError, e.message
          end
        end
      end
    end
  end
end
