require 'hat_trick/step'
require 'hat_trick/wizard_steps'
require 'hat_trick/wizard'

module HatTrick
  class WizardDefinition
    include WizardSteps

    attr_reader :config
    attr_accessor :before_callback_for_all_steps, :after_callback_for_all_steps

    def initialize(config)
      @config = config
      @steps = []
    end

    def make_wizard_for(controller)
      Rails.logger.debug "Making new wizard instance"
      wizard = HatTrick::Wizard.new(self)
      wizard.controller = controller
      wizard.alias_action_methods
      wizard
    end

    def configured_create_url
      config.create_url
    end

    def configured_update_url
      config.update_url
    end
  end
end
