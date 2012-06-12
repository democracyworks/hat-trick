module HatTrick
  module ModelMethods
    extend ActiveSupport::Concern
    mattr_accessor :validation_groups

    attr_accessor :_dummy # so the dummy field will have something to set

    included do
      alias_method_chain :perform_validations, :hat_trick
      alias_method_chain :as_json, :model_name
    end

    def self.set_current_validation_group_for(klass, validation_group_name)
      self.validation_groups ||= {}
      validation_groups[klass.to_s.underscore] = validation_group_name
    end

    def self.current_validation_group_for(klass)
      validation_groups[klass.to_s.underscore]
    end

    def perform_validations_with_hat_trick(*args, &block)
      enable_current_validation_group
      perform_validations_without_hat_trick(*args, &block)
    end

    def as_json_with_model_name(*args, &block)
      json = as_json_without_model_name(*args, &block)
      json.merge! :__name__ => self.class.to_s.underscore if json.respond_to?(:merge!)
    end

    private

    # don't call this method 'current_validation_group', it conflicts with
    # the gem
    def current_step_validation_group
      HatTrick::ModelMethods.current_validation_group_for(self.class)
    end

    def enable_current_validation_group
      enable_validation_group current_step_validation_group
    end
  end
end
