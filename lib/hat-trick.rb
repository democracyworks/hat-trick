require "hat_trick/version"
require "active_support"
require "active_support/core_ext/module"
require "hat_trick/engine"
require "hat_trick/dsl"
require "gon"

::ActionController::Base.send(:include, HatTrick::DSL)
