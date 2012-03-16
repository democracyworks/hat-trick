require "hat_trick/version"
require "hat_trick/rails_engine"
require "hat_trick/dsl"

module HatTrick

end

::ActionController::Base.send(:extend, HatTrick::DSL::ClassMethods)
::ActionController::Base.send(:include, HatTrick::DSL::InstanceMethods)
