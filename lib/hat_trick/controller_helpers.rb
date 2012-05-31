module HatTrick
  module ControllerHelpers

    private

    def params_model_name
      params.each do |k,v|
        return class_name(k) if v.is_a?(Hash) && is_model?(k)
      end
      nil
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
      model_name = params_model_name
      return nil if model_name.nil?
      begin
        model_class = params_model_name.constantize
      rescue NameError
        Rails.logger.error "Could not find model class #{params_model_name.camelize}"
        nil
      else
        model_class
      end
    end

    def setup_validation_group_for(wizard_step)
      klass = model_class
      return if klass.nil?
      step_name = wizard_step.name
      validation_groups = ::ActiveRecord::Base.validation_group_classes[klass] || []
      unless validation_groups.include?(step_name)
        klass.validation_group(step_name, :fields => params.keys)
      end
      HatTrick::ModelMethods.set_current_validation_group_for(model_class, step_name)
      unless klass.included_modules.include?(HatTrick::ModelMethods)
        klass.send(:include, HatTrick::ModelMethods)
      end
    end
  end
end
