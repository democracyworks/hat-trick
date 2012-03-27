require "hat_trick/version"
require "hat_trick/rails_engine"
require "hat_trick/dsl"
require "gon"

::ActionController::Base.send(:include, HatTrick::DSL)
