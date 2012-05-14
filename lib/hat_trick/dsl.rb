# define these before the requires b/c wizard_definition expects it to exist
module HatTrick
  module DSL
  end
end

require 'hat_trick/wizard_definition'
require 'hat_trick/controller_hooks'

module HatTrick
  module DSL
    extend ActiveSupport::Concern

    attr_accessor :ht_wizard

    delegate :model, :previously_visited_step, :to => :ht_wizard

    def next_step(name=nil)
      if name.nil?
        # getter
        ht_wizard.next_step
      else
        # setter
        step = ht_wizard.find_step(name)
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

          @wizard_def = HatTrick::WizardDefinition.new

          yield

        else
          raise ArgumentError, "wizard called without a block"
        end
      end

      def create_url(url)
        wizard_def.configured_create_url = url
      end

      def update_url(url)
        wizard_def.configured_update_url = url
      end

      def step(name, args={}, &block)
        wizard_def.add_step(name, args)
        instance_eval &block if block_given?
      end

      def repeat_step(name)
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
        wizard_def.last_step.skipped = true
      end

      def button_to(name, options=nil)
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

      def set_contents(&block)
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

