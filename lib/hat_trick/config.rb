module HatTrick
  class Config
    attr_reader :wizard_def

    def initialize(wizard_def)
      @wizard_def = wizard_def
    end

    def create_url=(url)
      wizard_def.configured_create_url = url
    end

    def update_url=(url)
      wizard_def.configured_update_url = url
    end
  end
end
