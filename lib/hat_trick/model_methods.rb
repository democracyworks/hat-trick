module HatTrick
  module ModelMethods
    extend ActiveSupport::Concern
    mattr_accessor :validation_groups
    mattr_accessor :dynamic_validation_groups

    attr_accessor :_dummy # so the dummy field will have something to set

    included do
      alias_method_chain :perform_validations, :hat_trick if instance_methods.include?(:perform_validations)
      alias_method_chain :as_json, :model_name if instance_methods.include?(:as_json)
    end

    def self.dynamic_validation_groups
      @dynamic_validation_groups ||= []
    end

    def self.set_current_validation_group_for(klass, validation_group_name, dynamic)
      self.validation_groups ||= {}
      validation_groups[klass.to_s.underscore] = validation_group_name
      if dynamic && !dynamic_validation_groups.include?(validation_group_name)
        dynamic_validation_groups << validation_group_name
      end
    end

    def self.current_validation_group_for(klass)
      return nil unless validation_groups
      validation_groups[klass.to_s.underscore]
    end

    def self.clear_current_validation_group_for(klass)
      unless validation_groups.nil?
        Rails.logger.debug "Clearing current validation groups for #{klass.to_s.underscore}"
        validation_groups.delete klass.to_s.underscore
      end
    end

    def perform_validations_with_hat_trick(*args, &block)
      enable_current_validation_group
      perform_validations_without_hat_trick(*args, &block)
    end

    def disable_validation_groups
      if respond_to?(:disable_validation_group)
        Rails.logger.debug "Disabling validation groups"
        disable_validation_group
      end
      HatTrick::ModelMethods.clear_current_validation_group_for(self.class)
    end

    def as_json_with_model_name(*args, &block)
      json = as_json_without_model_name(*args, &block)
      json.merge! :__name__ => self.class.to_s.underscore if json.respond_to?(:merge!)
    end

    private

    # don't call this method 'current_validation_group', it conflicts with
    # the validation_group gem
    def current_step_validation_group
      HatTrick::ModelMethods.current_validation_group_for(self.class)
    end

    def enable_current_validation_group
      validation_group = current_step_validation_group
      if validation_group
        Rails.logger.debug "Enabling validation group #{validation_group}"
        enable_validation_group validation_group
      else
        Rails.logger.debug "NOT enabling a validation group"
      end
    end
  end
end
