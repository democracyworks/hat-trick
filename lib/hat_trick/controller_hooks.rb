module HatTrick
  module ControllerHooks
    extend ActiveSupport::Concern

    included do
      alias_method_chain :render, :hat_trick
    end

    def self.def_action_method_aliases!(action_methods)
      action_methods.each do |meth|
        Rails.logger.info "Aliasing #{meth}"
        module_eval <<-RUBY_EVAL
          def #{meth}_with_hat_trick(*args)
            Rails.logger.info "#{meth}_with_hat_trick called"
            #{meth}_hook(*args) if respond_to?("#{meth}_hook", :include_private)
            common_hook(*args)
            #{meth}_without_hat_trick(*args)
          end
          private "#{meth}_with_hat_trick"
        RUBY_EVAL
      end
      true
    end

    private

    def params_model_name
      params.each do |k,v|
        return k if v.is_a?(Hash)
      end
      nil
    end

    def model_class
      begin
        model_class = params_model_name.camelize.constantize
      rescue
        Rails.logger.error "Could not find model class #{params_model_name.camelize}"
        nil
      else
        model_class
      end
    end

    def setup_validation_group_for(wizard_step)
      klass = model_class
      step_name = wizard_step.name
      validation_groups = ::ActiveRecord::Base.validation_group_classes[klass]
      unless validation_groups.include?(step_name)
        klass.validation_group(step_name, :fields => params.keys)
      end
      HatTrick::ModelMethods.set_current_validation_group_for(model_class, step_name)
      unless klass.included_modules.include?(HatTrick::ModelMethods)
        klass.send(:include, HatTrick::ModelMethods)
      end
    end

    def create_hook(*args)
      setup_validation_group_for(ht_wizard.current_step)
    end

    def update_hook(*args)
      setup_validation_group_for(ht_wizard.current_step)
    end

    def common_hook(*args)
      # nothing here for now
    end

    def render_with_hat_trick(*args)
      if args.first.has_key?(:json)
        model = args[0][:json]
        ht_wizard.model = model
      end

      wizard_metadata = {
        :url => ht_wizard.current_form_url,
        :method => ht_wizard.current_form_method,
      }

      # this sets the wizard_metadata for the initial page load
      gon.wizard_metadata = wizard_metadata

      if ht_wizard.model && args[0].has_key?(:json)
        # this sets the wizard metadata for subsequent AJAX requests
        args[0][:json] = { :model => ht_wizard.model, :ht => wizard_metadata }
      end

      render_without_hat_trick(*args)
    end
  end

  module ModelMethods
    extend ActiveSupport::Concern
    mattr_accessor :current_validation_group

    included do
      alias_method_chain :save, :hat_trick
    end

    def self.set_current_validation_group_for(klass, validation_group_name)
      self.current_validation_group ||= {}
      current_validation_group[klass.to_s.underscore] = validation_group_name
    end

    def self.current_validation_group_for(klass)
      current_validation_group[klass.to_s.underscore]
    end

    def save_with_hat_trick(*args)
      Rails.logger.info "Saving #{self.inspect} with hat trick"
      enable_validation_group HatTrick::ModelMethods.current_validation_group_for(self.class)
      save_without_hat_trick(*args)
    end
  end
end
