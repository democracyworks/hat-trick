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

        if params.has_key?('_ht_meta')
          step_name = params['_ht_meta']['step']
          @ht_wizard.current_step = step_name if step_name
        end
      end
    end

    class WizardContext
      attr_reader :wizard_def
      attr_accessor :wizard

      delegate :model, :previously_visited_step, :to => :wizard

      def initialize(wizard_def)
        @wizard_def = wizard_def
      end

      def step(name, args={}, &block)
        wizard_def.add_step(name, args)
        instance_eval &block if block_given?
      end

      def next_step(name=nil)
        if name.nil?
          wizard.next_step
        else
          raise "next_step should only be called from an after block" if wizard.nil?
          step = wizard.find_step(name)
          wizard.current_step.next_step = step
        end
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
          # TODO: Might turn all these into run-time methods; which would get
          # rid of this wizard / wizard_def distinction
        else
          # replace the step we're in the middle of defining w/ new_step
          wizard_def.replace_step(wizard_def.last_step, new_step)
        end
      end

      def skip_this_step
        if wizard
          wizard.skip_step(wizard.current_step)
        else
          # skip_this_step in wizard definition context means the step
          # can be explicitly jumped to, but won't be in the normal flow
          wizard_def.last_step.skipped = true
        end
      end

      def button_to(name, options=nil)
        if wizard
          raise "button_to not yet supported in before/after blocks"
        end
        label = options[:label] if options
        label ||= name.to_s.humanize
        step = wizard_def.last_step
        step.buttons = step.buttons.merge(name => label)
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

