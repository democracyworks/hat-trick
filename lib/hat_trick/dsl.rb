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

    module WizardMethods
      def step(name, args={}, &block)
        wizard_def.add_step(name, args)
        instance_eval &block if block_given?
      end

      def next_step(name)
        step = wizard_def.find_step(name)
        wizard_def.next_step = step
      end

      def repeat_step(name)
        step = wizard_def.find_step(name)
        wizard_def.add_step step.dup
      end

      def skip_this_step
        wizard_def.last_step = wizard_def.next_step
      end

      def before_this_step(&block)
        wizard_def.last_step.before_callback = block
      end

      def after_this_step(&block)
        wizard_def.last_step.after_callback = block
      end
    end

    class WizardContext
      attr_reader :wizard_def
      include HatTrick::DSL::WizardMethods

      def initialize(wizard_def)
        @wizard_def = wizard_def
      end
    end
  end
end

