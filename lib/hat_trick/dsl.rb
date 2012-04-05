require 'hat_trick/wizard_definition'
require 'hat_trick/controller_hooks'

module HatTrick
  module DSL
    extend ActiveSupport::Concern

    module ClassMethods
      def wizard(&block)
        if block_given?
          include HatTrick::DSL::ControllerInstanceMethods
          include HatTrick::ControllerHooks

          @wizard_def = HatTrick::WizardDefinition.new

          @wizard_dsl = HatTrick::DSL::WizardContext.new(@wizard_def)
          @wizard_dsl.instance_eval &block

        else
          raise ArgumentError, "wizard called without a block"
        end
      end
    end

    module ControllerInstanceMethods
      extend ActiveSupport::Concern

      included do
        before_filter :setup_wizard
      end

      private

      attr_reader :ht_wizard

      def setup_wizard
        wizard_def = self.class.instance_variable_get("@wizard_def")
        @ht_wizard = wizard_def.get_wizard(self)
      end
    end

    class WizardContext
      attr_reader :wizard_def
      attr_accessor :wizard

      delegate :model, :to => :wizard

      def initialize(wizard_def)
        @wizard_def = wizard_def
      end

      def step(name, args={}, &block)
        wizard_def.add_step(name, args)
        instance_eval &block if block_given?
      end

      def next_step(name)
        step = wizard_def.find_step(name)
        raise "next_step should only be called from a callback" if wizard.nil?
        current_step = wizard.current_step
        wizard.add_step_override(current_step, :after, step)
      end

      def repeat_step(name)
        repeated_step = wizard_def.find_step(name)
        raise ArgumentError, "Couldn't find step named #{name}" unless repeated_step
        new_step = repeated_step.dup
        # use the repeated step's fieldset id
        new_step.fieldset = repeated_step.fieldset
        # but use the current step's name
        new_step.name = wizard_def.last_step.name
        # set the repeated flag
        new_step.repeat_of = repeated_step
        if wizard
          # TODO: See if this actually works
          wizard.add_step_override(repeated_step, :after, new_step)
        else
          # replace the step we're in the middle of defining w/ new_step
          wizard_def.replace_step(wizard_def.last_step, new_step)
        end
      end

      def skip_this_step
        if wizard
          skip_to_step = wizard.next_step
          if skip_to_step
            wizard.current_step = skip_to_step
          else
            wizard.finish!
          end
        else
          raise "skip_this_step should only be called in a before_this_step callback"
        end
      end

      def before(&block)
        wizard_def.last_step.before_callback = block
      end

      def after(&block)
        wizard_def.last_step.after_callback = block
      end

      def include_data(key, &block)
        wizard_def.last_step.include_data = { key.to_sym => block }
      end
    end
  end
end

