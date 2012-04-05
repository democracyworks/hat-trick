require 'hat_trick/controller_hooks'

module HatTrick
  class Wizard
    attr_accessor :current_step, :controller, :model, :step_overrides
    attr_reader :wizard_def, :wizard_dsl_context

    delegate :first_step, :last_step, :find_step, :each, :to_ary, :to_json,
             :empty?, :step_after, :step_before, :steps,
             :to => :wizard_def

    def initialize(wizard_def)
      @wizard_def = wizard_def
      @wizard_dsl_context = DSL::WizardContext.new(@wizard_def)
      @wizard_dsl_context.wizard = self
      @step_overrides = {}
    end

    def controller=(new_controller)
      @controller = new_controller
      step = if controller.params.has_key?('_ht_meta')
        find_step controller.params['_ht_meta']['step']
      end
      self.current_step = step if step
    end

    def current_step=(step)
      raise "Don't set current_step to nil" if step.nil?
      @current_step = step
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

    def add_step_override(source_step, override_type, target_step)
      source = source_step.to_sym
      @step_overrides[source] ||= {}
      @step_overrides[source][override_type.to_sym] = target_step
    end

    def next_step
      current = current_step.to_sym
      if step_overrides.has_key?(current) && step_overrides[current].has_key?(:after)
        step_overrides[current][:after]
      else
        step_after current_step
      end
    end

    def started?
      !current_step.nil?
    end

    def start!
      self.current_step = first_step
      current_step.run_before_callback!(controller, wizard_dsl_context)
    end

    def finish!
      # Do something here
    end

    def advance_step!(current_step_name)
      step = find_step(current_step_name)
      self.current_step = step
      step.run_after_callback!(controller, wizard_dsl_context)
      if current_step == last_step
        finish!
      else
        self.current_step = next_step
        current_step.run_before_callback!(controller, wizard_dsl_context)
      end
    end

    def include_data
      return {} unless model
      inc_data = current_step.run_include_data_callback!(controller, model)
      data_key = current_step.include_data_key
      { data_key.to_s.camelize(:lower) => inc_data }
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
