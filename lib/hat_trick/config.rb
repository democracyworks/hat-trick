module HatTrick
  class Config
    attr_accessor :create_url, :update_url, :back_button_label, :next_button_label

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
