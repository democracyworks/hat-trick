module HatTrick
  class Config
    attr_accessor :create_url, :update_url, :back_button_label,
                  :next_button_label, :back_button_label_i18n_key,
                  :next_button_label_i18n_key

    def initialize(settings={})
      settings.each do |k,v|
        setter = "#{k}="
        if respond_to?(setter)
          send(setter, v)
        end
      end
    end
  end
end
