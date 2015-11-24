# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "hat_trick/version"

Gem::Specification.new do |s|
  s.name        = "hat-trick"
  s.version     = HatTrick::VERSION
  s.authors     = ["Wes Morgan"]
  s.email       = ["cap10morgan@gmail.com"]
  s.homepage    = "https://github.com/turbovote/hat-trick"
  s.summary     = %q{A simple DSL for creating client-side multi-step forms in Rails.}
  s.description = %q{Hat-Trick brings together jQuery, validation_group, and Ajax to make multi-step forms awesome. It tries to insulate you from this complexity by providing a simple yet powerful DSL for defining the steps of your form and their behavior.}

  s.rubyforge_project = "hat-trick"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", "~> 2.99"
  s.add_development_dependency "mocha"

  s.add_runtime_dependency "rails", ">= 3.1"
  s.add_runtime_dependency "validation_group"
  s.add_runtime_dependency "gon"
end
