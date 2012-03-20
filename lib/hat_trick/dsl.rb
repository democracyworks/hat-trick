require 'hat_trick/wizard'

module HatTrick
  module DSL
    extend ActiveSupport::Concern

    module ClassMethods
      def wizard(&blk)
        if block_given?
          ::ActionController::Base.send(:include, HatTrick::ControllerHooks)
          # alias_method_chain :new, :hat_trick
          # alias_method_chain :create, :hat_trick
          # alias_method_chain :update, :hat_trick

          @wizard = HatTrick::Wizard.new
          @wizard_dsl = HatTrick::DSL::Wizard.new(@wizard)
          @wizard_dsl.instance_eval &blk
        else
          raise ArgumentError, "wizard called without a block"
        end
      end

    end

    module InstanceMethods
      def current_wizard
        wizard = self.class.instance_variable_get("@wizard")
        raise "No wizard has been declared for this controller" unless wizard
        wizard
      end
    end

    module InWizardBlock
      def step(name, args={}, &blk)
        current_step = wizard.add_step(name, args)
        instance_eval &blk if block_given?
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

      def before_this_step(&blk)
        wizard.current_step.before_callback = blk
      end

      def after_this_step(&blk)
        wizard.current_step.after_callback = blk
      end
    end

    class Wizard
      attr_reader :wizard
      attr_accessor :current_step
      include HatTrick::DSL::InWizardBlock

      def initialize(wizard)
        @wizard = wizard
      end
    end
  end

  module ControllerHooks
    def new_with_hat_trick
      Rails.logger.info "new_with_hat_trick called"
    end

    def create_with_hat_trick
      Rails.logger.info "create_with_hat_trick called"
    end

    def update_with_hat_trick
      Rails.logger.info "update_with_hat_trick called"
    end
  end
end

