module HatTrick
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
