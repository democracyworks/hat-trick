require 'hat_trick/form_helper'

module HatTrick
  class Engine < ::Rails::Engine
    # just defining this causes Rails to look for assets inside this gem

    initializer 'hat-trick.form_helpers' do
      ActiveSupport.on_load(:action_view) do
        include HatTrick::FormHelper
      end
    end
  end
end
