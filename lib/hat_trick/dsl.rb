require 'hat_trick/wizard'

module HatTrick
  module DSL
    extend ActiveSupport::Concern

    module ClassMethods
      def wizard(&blk)
        if block_given?
          include HatTrick::DSL::ControllerInstanceMethods
          include HatTrick::DSL::HelperMethods

          include HatTrick::ControllerHooks
          %w(new edit create update).each do |meth|
            # TODO: Figure out how to hook into these methods when they don't yet exist
            # OR: Figure out a cleaner way to do this
            # alias_method_chain meth, :hat_trick
          end

          @wizard = HatTrick::Wizard.new
          @wizard_dsl = HatTrick::DSL::WizardContext.new(@wizard)

          # dsl_metaclass = class << @wizard_dsl; self; end
          #
          # dsl_metaclass.send(:define_method, :method_missing) do |*args|
          #   if self.respond_to?(args[0])
          #     self.send(args[0], args[1..-1])
          #   else
          #     super(*args)
          #   end
          # end

          # dsl_metaclass.send(:define_method, :respond_to?) do |meth|
          #   if self.respond_to?(meth)
          #     true
          #   else
          #     super(meth)
          #   end
          # end

          @wizard_dsl.instance_eval &blk

        else
          raise ArgumentError, "wizard called without a block"
        end
      end
    end

    module HelperMethods
      extend ActiveSupport::Concern

      included do
        helper_method :wizard_url
      end

      def wizard_url
        self.class.instance_variable_get("@wizard").current_form_url
      end
    end

    module ControllerInstanceMethods
      extend ActiveSupport::Concern

      included do
        before_filter :assign_controller
      end

      def current_wizard
        wizard = self.class.instance_variable_get("@wizard")
        raise "No wizard has been declared for this controller" unless wizard
        wizard
      end

      def assign_controller
        current_wizard.controller = self
      end
    end

    module WizardMethods
      def create_url(&blk)
        if block_given?
          @wizard.create_url = @wizard.controller.instance_eval &blk
        end
      end

      def update_url(&blk)
        if block_given?
          @wizard.update_url = @wizard.controller.instance_eval &blk
        end
      end

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

    class WizardContext
      attr_reader :wizard
      attr_accessor :current_step
      include HatTrick::DSL::WizardMethods

      def initialize(wizard)
        @wizard = wizard
      end
    end
  end

  module ControllerHooks
    extend ActiveSupport::Concern

    def new_with_hat_trick
      Rails.logger.info "new_with_hat_trick called"
      new_without_hat_trick
    end

    def edit_with_hat_trick
      Rails.logger.info "edit_with_hat_trick called"
      edit_without_hat_trick
    end

    def create_with_hat_trick
      Rails.logger.info "create_with_hat_trick called"
      create_without_hat_trick
    end

    def update_with_hat_trick
      Rails.logger.info "update_with_hat_trick called"
      update_without_hat_trick
    end
  end
end

