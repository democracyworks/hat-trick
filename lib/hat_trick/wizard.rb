require 'hat_trick/controller_hooks'
require 'hat_trick/wizard_steps'
require 'hat_trick/dsl'

module HatTrick
  class Wizard
    include WizardSteps

    attr_accessor :controller, :model
    attr_reader :current_step, :wizard_def, :steps

    def initialize(wizard_def)
      @wizard_def = wizard_def
      @steps = @wizard_def.steps.map { |s| HatTrick::Step.new(s, self) }
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

    def session
      controller.session unless controller.nil?
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
      wizard_def.configured_create_url or
      controller.url_for(:controller => controller.controller_name,
                         :action => 'create', :only_path => true)
    end

    def update_url
      wizard_def.configured_update_url or
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
      session["hat-trick.steps_visited"] = []
      self.current_step = first_step
      run_before_callback
    end

    def finish
      # Do something here
      # Such as: Force the wizard to display the "done" page
      Rails.logger.info "WIZARD FINISHED!"
    end

    def run_before_callback(step=current_step)
      step.run_before_callback(controller, model)
    end

    def run_after_callback(step=current_step)
      step.run_after_callback(controller, model)
    end

    def advance_step(next_step_name=nil)
      # clean up current step
      current_step.visited = true
      run_after_callback

      # see if there is a requested next step
      requested_next_step = find_step(next_step_name) unless next_step_name.nil?

      # finish if we're on the last step
      if current_step == last_step && !requested_next_step
        finish
      else # we're not on the last step
        if requested_next_step
          Rails.logger.info "Force advancing to step: #{requested_next_step}"
          self.current_step = requested_next_step
          run_before_callback
          # if the step was explicitly requested, we ignore #skipped?
        else
          Rails.logger.info "Advancing to step: #{next_step}"
          self.current_step = next_step
          run_before_callback
          # Running the before callback may have marked current_step as skipped
          while current_step.skipped?
            self.current_step = next_step
            run_before_callback
          end
        end
      end
    end

    def include_data
      return {} if model.nil?
      inc_data = {}
      include_data_steps = steps_before(current_step) << current_step
      include_data_steps.each do |step|
        step_data = step.run_include_data_callback(controller, model)
        return {} if step_data.nil? || !step_data.respond_to?(:as_json)
        step_key = step.include_data_key.to_s.camelize(:lower)
        begin
          inc_data[step_key] = camelize_hash_keys(step_data)
        rescue NoMethodError => e
          Rails.logger.error "Unable to serialize data for step #{step}: #{e}"
        end
      end
      inc_data
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

    def camelize_hash_keys(_hash)
      hash = {}
      if _hash.respond_to?(:each)
        _hash.each do |k,v|
          hash[k.to_s.camelize(:lower)] = v
        end
      else
        hash = _hash
      end
      hash
    end
  end
end
