require 'hat_trick/controller_hooks'

module HatTrick
  class Wizard
    attr_accessor :current_step, :controller, :model
    attr_reader :wizard_definition

    delegate :first_step, :last_step, :find_step, :to => :wizard_definition

    def initialize(wizard_definition)
      @wizard_definition = wizard_definition
    end

    def controller=(new_controller)
      @controller = new_controller
      step = if controller.params.has_key?('_ht_meta')
        find_step controller.params['_ht_meta']['step']
      end
      self.current_step = step if step
    end

    def model_created?
      !(model.nil? || (model.respond_to?(:new_record?) && model.new_record?))
    end

    def current_form_url
      model_created? ? update_url : create_url
    end

    def current_form_method
      model_created? ? 'put' : 'post'
    end

    def create_url
      controller.url_for(:controller => controller.controller_name,
                         :action => 'create', :only_path => true)
    end

    def update_url
      if model_created?
        controller.url_for(:controller => controller.controller_name,
                           :action => 'update', :id => model,
                           :only_path => true)
      else
        nil
      end
    end

    def start!
      self.current_step = first_step
      current_step.run_before_callback!(controller)
    end

    def advance_step!(current_step_name)
      step = find_step(current_step_name)
      self.current_step = step
      step.run_after_callback!(controller)
      self.current_step = step.next_step
      current_step.run_before_callback!(controller)
    end

    def alias_action_methods!
      action_methods = controller.action_methods.reject do |m|
        /^render/ =~ m.to_s ||
        controller.respond_to?("#{m}_with_hat_trick", :include_private)
      end
      HatTrick::ControllerHooks.def_action_method_aliases!(action_methods)
      action_methods.each do |meth|
        controller.class.send(:alias_method_chain, meth, :hat_trick)
        controller.class.send(:private, "#{meth}_without_hat_trick")
      end
    end
  end
end
