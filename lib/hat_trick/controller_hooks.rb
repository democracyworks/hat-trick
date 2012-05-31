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
        Rails.logger.info "Aliasing #{meth}"
        module_eval <<-RUBY_EVAL
          def #{meth}_with_hat_trick(*args)
            Rails.logger.info "#{meth}_with_hat_trick called"
            #{meth}_hook(*args) if respond_to?("#{meth}_hook", :include_private)
            common_hook(*args) if respond_to?(:common_hook, :include_private)
            #{meth}_without_hat_trick(*args)
          end
          private "#{meth}_with_hat_trick"
        RUBY_EVAL
      end
      true
    end

    private

    def create_hook(*args)
      setup_validation_group_for(ht_wizard.current_step)
    end

    def update_hook(*args)
      setup_validation_group_for(ht_wizard.current_step)
    end

    def render_with_hat_trick(*args)
      rendered = args.first
      if rendered && rendered.has_key?(:json)
        model = rendered[:json]
        ht_wizard.model = model
      end

      if params.has_key?('_ht_meta')
        next_step = params['_ht_meta']['next_step']
        ht_wizard.advance_step(next_step)
      end

      wizard_metadata = {
        :url => ht_wizard.current_form_url,
        :method => ht_wizard.current_form_method,
        :currentStep => ht_wizard.current_step,
      }

      include_data = ht_wizard.include_data

      # this sets the gon data (JS hatTrick object) for the initial page load
      gon.metadata = wizard_metadata
      gon.data = include_data
      gon.model = ht_wizard.model

      # this sets the wizard metadata for subsequent AJAX requests
      if ht_wizard.model && rendered.has_key?(:json)
        args[0][:json] = { :model => ht_wizard.model,
                           :metadata => wizard_metadata }
        args[0][:json].merge!( :data => include_data )
      end

      render_without_hat_trick(*args)
    end
  end
end
