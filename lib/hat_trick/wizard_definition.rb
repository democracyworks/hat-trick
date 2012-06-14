require 'hat_trick/step'
require 'hat_trick/wizard_steps'
require 'hat_trick/wizard'

module HatTrick
  class WizardDefinition
    include WizardSteps

    attr_accessor :configured_create_url, :configured_update_url

    def initialize
      @steps = []
    end

    def get_wizard(controller)
      controller.send(:ht_wizard) or (
        wizard = HatTrick::Wizard.new(self)
        wizard.controller = controller
        wizard.alias_action_methods
        wizard
      )
    end
  end
end
