require 'hat_trick/wizard'
require 'hat_trick/controller_hooks'

module HatTrick
  module DSL
    extend ActiveSupport::Concern

    module ClassMethods
      def wizard(&block)
        if block_given?
          include HatTrick::DSL::ControllerInstanceMethods
          include HatTrick::ControllerHooks

          @wizard = HatTrick::Wizard.new

          @wizard_dsl = HatTrick::DSL::WizardContext.new(@wizard)
          @wizard_dsl.instance_eval &block

        else
          raise ArgumentError, "wizard called without a block"
        end
      end
    end

    module ControllerInstanceMethods
      extend ActiveSupport::Concern

      included do
        before_filter :assign_controller
      end

      private

      def ht_wizard
        @wizard ||= self.class.instance_variable_get("@wizard")
        raise "No wizard has been declared for this controller" unless @wizard
        @wizard
      end

      def assign_controller
        ht_wizard.controller = self
      end
    end

    module WizardMethods
      def step(name, args={}, &block)
        current_step = wizard.add_step(name, args)
        instance_eval &block if block_given?
      end

      def next_step(name)
        step = wizard.find_step(name)
        wizard.next_step = step
      end

      def repeat_step(name)
        step = wizard.find_step(name)
        wizard.add_step step.dup
      end

      def skip_this_step
        wizard.current_step = wizard.next_step
      end

      def before_this_step(&block)
        wizard.current_step.before_callback = block
      end

      def after_this_step(&block)
        wizard.current_step.after_callback = block
      end
    end

    class WizardContext
      attr_reader :wizard
      attr_accessor :current_step
      include HatTrick::DSL::WizardMethods

      def initialize(wizard)
        @wizard = wizard
      end
    end
  end
end

