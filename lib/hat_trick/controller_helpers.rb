module HatTrick
  module ControllerHelpers

    private

    def model_key
      params.each do |k,v|
        return k if v.is_a?(Hash) && is_model?(k)
      end
      nil
    end

    def params_model_name
      class_name model_key unless model_key.nil?
    end

    def is_model?(model_name)
      begin
        class_name(model_name).constantize
      rescue NameError
        return false
      end
      true
    end

    def class_name(hash_key)
      hash_key.to_s.camelize
    end

    def model_class
      return hat_trick_wizard.model.class if hat_trick_wizard.model

      # if that didn't work, try to grab it from the params hash
      model_name = params_model_name
      return nil if model_name.nil?

      begin
        model_klass = params_model_name.constantize
      rescue NameError
        Rails.logger.error "Could not find model class #{params_model_name.camelize}"
        nil
      else
        model_klass
      end
    end

    def setup_validation_group_for(wizard_step)
      klass = model_class
      if klass.nil?
        Rails.logger.warn "model class was nil when setting up validation group for #{wizard_step}"
        return
      end
      step_name = wizard_step.name
      validation_groups = ::ActiveRecord::Base.validation_group_classes[klass] || []
      dynamic_group_exists = HatTrick::ModelMethods.dynamic_validation_groups.include?(step_name)
      static_validation_group_exists = validation_groups.include?(step_name) && !dynamic_group_exists
      dynamic_validation_group = false

      if static_validation_group_exists
        Rails.logger.info "Not creating dynamic validation group for #{step_name} because a static one exists"
      else
        Rails.logger.info "Creating a dynamic validation group for #{step_name}"
        dynamic_validation_group = true
        validation_fields = params.keys # TODO: Try it without these (so only the model keys below)
        model = model_key
        if model
          validation_fields += params[model].keys
        end
        validation_fields = validation_fields.map(&:to_sym)
        klass.validation_group(step_name, :fields => validation_fields)
      end
      Rails.logger.info "Setting current validation group for model class #{model_class} to #{step_name}"
      HatTrick::ModelMethods.set_current_validation_group_for(model_class,
                                                              step_name,
                                                              dynamic_validation_group)
    end
  end
end
