require 'hat_trick/model_methods'
require 'hat_trick/controller_helpers'

module HatTrick
  module ControllerHooks
    extend ActiveSupport::Concern
    include ControllerHelpers

    included do
      alias_method_chain :render, :hat_trick
    end

    def self.def_action_method_aliases(action_methods)
      action_methods.each do |meth|
        unless respond_to?(:"#{meth}_with_hat_trick")
          Rails.logger.debug "Defining #{meth}_with_hat_trick"
          module_eval <<-RUBY_EVAL
            def #{meth}_with_hat_trick(*args)
              Rails.logger.debug "#{meth}_with_hat_trick called"
              if respond_to?("#{meth}_hook", :include_private)
                #{meth}_hook(*args)
              end
              common_hook(*args) if respond_to?(:common_hook, :include_private)
              #{meth}_without_hat_trick(*args)
            end
            private "#{meth}_with_hat_trick"
          RUBY_EVAL
        end
      end
      true
    end

    private

    def create_hook(*args)
      setup_validation_group_for(hat_trick_wizard.current_step)
    end

    def update_hook(*args)
      setup_validation_group_for(hat_trick_wizard.current_step)
    end

    def render_with_hat_trick(*args, &block)
      rendered = args.first
      if rendered && rendered.has_key?(:json)
        hat_trick_wizard.model = rendered[:json]
      else
        Rails.logger.warn "No model found in render args #{args.inspect}; model is #{hat_trick_wizard.model.inspect}"
      end

      if params.has_key?('_ht_meta')
        next_step = params['_ht_step_link']
        hat_trick_wizard.advance_step(next_step)
      end

      wizard_metadata = {
        :externalRedirectURL => hat_trick_wizard.external_redirect_url,
        :url => hat_trick_wizard.current_form_url,
        :method => hat_trick_wizard.current_form_method,
        :currentStep => hat_trick_wizard.current_step,
        :percentComplete => hat_trick_wizard.percent_complete,
      }

      include_data = hat_trick_wizard.include_data

      # this sets the gon data (JS hatTrick object) for the initial page load
      gon.metadata = wizard_metadata
      gon.data = include_data
      gon.model = hat_trick_wizard.model
      gon.rails_env = Rails.env

      # this sets the wizard metadata for subsequent AJAX requests
      if hat_trick_wizard.model && rendered.has_key?(:json)
        args[0][:json] = { :model => hat_trick_wizard.model,
                           :metadata => wizard_metadata }
        args[0][:json].merge!( :data => include_data )
      end

      # unset redirects for subsequent steps
      hat_trick_wizard.external_redirect_url = nil

      render_without_hat_trick(*args, &block)
    end
  end
end
