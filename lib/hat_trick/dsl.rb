require 'hat_trick/wizard_definition'
require 'hat_trick/controller_hooks'
require 'hat_trick/config'

module HatTrick
  module DSL
    extend ActiveSupport::Concern

    attr_accessor :ht_wizard, :configure_callback, :_ht_config

    delegate :model, :previously_visited_step, :to => :ht_wizard

    included do
      alias_method_chain :initialize, :hat_trick
    end

    def initialize_with_hat_trick(*args, &block)
      @_ht_config = HatTrick::Config.new(self.class.wizard_def)
      if configure_callback.is_a?(Proc)
        ht_wizard.controller.instance_exec(@_ht_config, &configure_callback)
      end
      initialize_without_hat_trick(*args, &block)
    end

    def next_step(name=nil)
      if name.nil?
        # getter
        ht_wizard.next_step
      else
        # setter
        step = ht_wizard.find_step(name)
        # explicitly set steps should not be skipped
        step.skipped = false
        ht_wizard.current_step.next_step = step
      end
    end

    def skip_this_step
      ht_wizard.skip_step(ht_wizard.current_step)
    end

    module ClassMethods
      attr_reader :wizard_def

      def wizard(&block)
        if block_given?
          include HatTrick::DSL::ControllerInstanceMethods
          include HatTrick::ControllerHooks

          ::ActiveRecord::Base.send(:include, HatTrick::ModelMethods)

          @wizard_def = HatTrick::WizardDefinition.new

          yield

        else
          raise ArgumentError, "wizard called without a block"
        end
      end

      def configure(&block)
        raise "Must pass a block to configure" unless block_given?
        @config_callback = block
      end

      def step(name, args={}, &block)
        raise "step must be called from within a wizard block" unless wizard_def
        wizard_def.add_step(name, args)
        instance_eval &block if block_given?
      end

      def repeat_step(name)
        raise "repeat_step must be called from within a wizard block" unless wizard_def
        repeated_step = wizard_def.find_step(name)
        raise ArgumentError, "Couldn't find step named #{name}" unless repeated_step
        new_step = repeated_step.dup
        # use the repeated step's fieldset id
        new_step.fieldset = repeated_step.fieldset
        # but use the current step's name
        new_step.name = wizard_def.last_step.name
        # replace the step we're in the middle of defining w/ new_step
        wizard_def.replace_step(wizard_def.last_step, new_step)
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
        label = options[:label]
        label ||= step_name.to_s.humanize

        name = options[:name]
        name ||= step_name.to_s.parameterize

        value = options[:value]
        value ||= step_name.to_s.parameterize

        if options
          id = options[:id]
          css_class = options[:class]
        end

        step = wizard_def.last_step
        button = { :name => name, :value => value, :label => label }
        button[:id] = id unless id.nil?
        button[:class] = css_class unless css_class.nil?
        step.buttons << { step_name => button }
      end

      def before(&block)
        raise "before must be called from within a wizard block" unless wizard_def
        wizard_def.last_step.before_callback = block
      end

      def after(&block)
        raise "after must be called from within a wizard block" unless wizard_def
        wizard_def.last_step.after_callback = block
      end

      def include_data(key, &block)
        raise "include_data must be called from within a wizard block" unless wizard_def
        wizard_def.last_step.include_data = { key.to_sym => block }
      end

      def set_contents(&block)
        raise "set_contents must be called from within a wizard block" unless wizard_def
        current_step_name = wizard_def.last_step.to_sym
        include_data "hat_trick_step_contents" do |wiz, model|
          { current_step_name => instance_exec(wiz, model, &block) }
        end
      end
    end

    module ControllerInstanceMethods
      extend ActiveSupport::Concern

      included do
        before_filter :setup_wizard
      end

      private

      def setup_wizard
        wizard_def = self.class.instance_variable_get("@wizard_def")
        @ht_wizard = wizard_def.get_wizard(self)

        if params.has_key?('_ht_meta')
          step_name = params['_ht_meta']['step']
          @ht_wizard.current_step = step_name if step_name
        end
      end
    end
  end
end
