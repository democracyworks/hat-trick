require 'hat_trick/controller_hooks'
require 'hat_trick/wizard_steps'

module HatTrick
  class Wizard
    include WizardSteps

    attr_accessor :controller, :model
    attr_reader :current_step, :wizard_def, :wizard_dsl_context, :steps

    def initialize(wizard_def)
      @wizard_def = wizard_def
      @wizard_dsl_context = DSL::WizardContext.new(@wizard_def)
      @wizard_dsl_context.wizard = self
      @steps = @wizard_def.steps.map { |s| HatTrick::Step.new(s) }
    end

    def controller=(new_controller)
      @controller = new_controller
    end

    def current_step=(_step)
      raise "Don't set current_step to nil" if _step.nil?
      step = find_step(_step)
      raise "#{step} is not a member of this wizard" unless step
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

    def next_step
      step = find_next_step
      while step.skipped? do
        step = find_step_after(step)
      end
      step
    end

    def previously_visited_step
      steps_before(current_step).select { |s| s.visited? }.last
    end

    def skip_step(_step)
      step = find_step(_step)
      step.skipped = true
    end

    def started?
      !current_step.nil?
    end

    def start
      self.current_step = first_step
      run_before_callback
    end

    def finish
      # Do something here
      # Such as: Force the wizard to display the "done" page
      Rails.logger.info "WIZARD FINISHED!"
    end

    def run_before_callback(step=current_step)
      step.run_before_callback(controller, wizard_dsl_context, model)
    end

    def run_after_callback(step=current_step)
      step.run_after_callback(controller, wizard_dsl_context, model)
    end

    def advance_step_with_debugger
      require 'ruby-debug'
      debugger
      advance_step
    end

    def advance_step(next_step_name=nil)
      requested_next_step = find_step(next_step_name) unless next_step_name.nil?
      run_after_callback
      if current_step == last_step && !requested_next_step
        finish
      else
        if requested_next_step
          Rails.logger.info "Force advancing to step: #{requested_next_step}"
          self.current_step = requested_next_step
        else
          Rails.logger.info "Advancing to step: #{next_step}"
          self.current_step = next_step
        end
        run_before_callback
        # Running the before callback may have marked current_step as skipped
        while current_step.skipped?
          self.current_step = next_step
          run_before_callback
        end
      end
    end

    def include_data
      return {} unless model
      inc_data = current_step.run_include_data_callback(controller, wizard_dsl_context, model)
      data_key = current_step.include_data_key
      { data_key.to_s.camelize(:lower) => inc_data }
    end

    def alias_action_methods
      action_methods = controller.action_methods.reject do |m|
        /^render/ =~ m.to_s ||
        controller.respond_to?("#{m}_with_hat_trick", :include_private)
      end
      HatTrick::ControllerHooks.def_action_method_aliases(action_methods)
      action_methods.each do |meth|
        controller.class.send(:alias_method_chain, meth, :hat_trick)
        controller.class.send(:private, "#{meth}_without_hat_trick")
      end
    end

    private

    def find_next_step
      find_step(current_step.next_step) or find_step_after(current_step)
    end

    def find_step_after(step)
      next_path_step = step_after step
      next_path_step or find_next_active_step(step)
    end
  end
end
