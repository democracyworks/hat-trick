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
      return if klass.nil?
      step_name = wizard_step.name
      validation_groups = ::ActiveRecord::Base.validation_group_classes[klass] || []
      unless validation_groups.include?(step_name)
        validation_fields = params.keys # TODO: Try it without these
        model = model_key
        if model
          validation_fields += params[model].keys
        end
        validation_fields = validation_fields.map &:to_sym
        klass.validation_group(step_name, :fields => validation_fields)
      end
      HatTrick::ModelMethods.set_current_validation_group_for(model_class, step_name)
      unless klass.included_modules.include?(HatTrick::ModelMethods)
        klass.send(:include, HatTrick::ModelMethods)
      end
    end
  end
end
