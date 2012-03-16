# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "hat_trick/version"

Gem::Specification.new do |s|
  s.name        = "hat-trick"
  s.version     = HatTrick::VERSION
  s.authors     = ["Wes Morgan"]
  s.email       = ["cap10morgan@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Rails wizards done right}
  s.description = %q{Combines jQuery Form Wizard, validation_group, with its own functionality for the perfect triple-play of Rails wizarding.}

  s.rubyforge_project = "hat-trick"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_development_dependency "mocha"
  s.add_development_dependency "ruby-debug19"

  s.add_runtime_dependency "rails", "~> 3.1"
  s.add_runtime_dependency "validation_group"
end
