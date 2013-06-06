require 'hat_trick/controller_hooks'
require 'hat_trick/wizard_steps'
require 'hat_trick/dsl'

module HatTrick
  class Wizard
    include WizardSteps

    attr_accessor :controller, :model, :external_redirect_url
    attr_reader :current_step, :wizard_def, :steps

    delegate :config, :to => :wizard_def

    def initialize(wizard_def)
      @wizard_def = wizard_def
      @steps = @wizard_def.steps.map { |s| HatTrick::Step.new(s, self) }
      @current_step = first_step
    end

    def controller=(new_controller)
      @controller = new_controller
    end

    def model=(new_model)
      Rails.logger.debug "Setting model for #{object_id} to #{new_model.inspect}"
      @model = new_model
    end

    def current_step=(_step)
      raise "Don't set current_step to nil" if _step.nil?
      step = find_step(_step)
      raise StepNotFound, "#{_step} is not a member of this wizard" unless step
      @current_step = step
    end

    def session
      if controller.nil?
        fake_session
      else
        controller.session
      end
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
        step = step_after(step)
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
      reset_step_session_data
      self.current_step ||= first_step
      run_before_callback
    end

    def steps_before_current
      steps_before(current_step)
    end

    def steps_after_current
      steps_after(current_step)
    end

    def visited_steps
      session["hat-trick.visited_steps"] ||= []
    end

    def skipped_steps
      session["hat-trick.skipped_steps"] ||= []
    end

    def percent_complete(step=current_step)
      percent = (steps_before_current.count.to_f / total_step_count) * 100
      if percent > 100.0
        100
      elsif percent <= 0
        0
      elsif percent < 5.0
        5
      else
        percent
      end
    end

    def steps_remaining=(count)
      self.override_step_count = steps_before_current.count + count
    end

    def steps_remaining
      total_step_count - steps_before_current.count
    end

    def override_step_count=(count)
      if count.nil?
        session.delete('hat-trick.override_step_count')
      else
        session['hat-trick.override_step_count'] = count
      end
    end

    def override_step_count
      session['hat-trick.override_step_count']
    end

    def total_step_count
      override_step_count or steps.count
    end

    def run_before_callback(step=current_step)
      step.run_before_callback(controller, model)
    end

    def run_after_callback(step=current_step)
      step.run_after_callback(controller, model)
    end

    def redirect_to_step(step)
      redirect_from = current_step.fieldset
      self.current_step = step
      current_step.redirect_from = redirect_from
    end

    def advance_step(next_step_name=nil)
      # clean up current step
      current_step.mark_as_visited
      before_callback_next_step = current_step.next_step
      run_after_callback
      after_callback_next_step = current_step.next_step

      # return if any redirects were requested
      return if external_redirect_url.present?

      # if after callback changed the next step, go to that one
      requested_next_step = if after_callback_next_step != before_callback_next_step
        after_callback_next_step
      else
        # use argument, if there was one
        find_step(next_step_name) unless next_step_name.nil?
      end

      # finish if we're on the last step
      if current_step == last_step && !requested_next_step
        raise "Tried to advance beyond the last step of the wizard"
      else # we're not on the last step
        if requested_next_step
          Rails.logger.debug "Force advancing to step: #{requested_next_step}"
          self.current_step = requested_next_step
          run_before_callback
          # if the step was explicitly requested, we ignore #skipped?
        else
          self.current_step = next_step
          run_before_callback
          # Running the before callback may have marked current_step as skipped
          while current_step.skipped?
            self.current_step = next_step
            run_before_callback
            # make sure we don't loop forever
            break if current_step == last_step
          end
          Rails.logger.debug "Advancing to step: #{current_step}"
        end
      end
    end

    def include_data
      include_data_for_step(current_step)
    end

    def include_data_for_step(step)
      return {} if model.nil?
      inc_data = step.include_data(controller, model)
      contents = step.step_contents(controller, model)
      inc_data.merge! contents
      inc_data.delete_if { |k,v| v.nil? }
      inc_data
    end

    def alias_action_methods
      action_methods = controller.action_methods.reject do |m|
        /^render/ =~ m.to_s or
        m.to_s.include?('!') or
        controller.respond_to?("#{m}_without_hat_trick", :include_private)
      end
      HatTrick::ControllerHooks.def_action_method_aliases(action_methods)
      action_methods.each do |m|
        controller.class.send(:alias_method_chain, m, :hat_trick)
        controller.class.send(:private, "#{m}_without_hat_trick")
      end
    end

    private

    def reset_step_session_data
      # TODO: Move this into a StepCollection class (maybe subclass Set)
      visited_steps = []
      skipped_steps = []
    end

    def fake_session
      Rails.logger.warn "Using a fake session object!"
      @fake_session ||= {}
    end

    def find_next_step
      find_step(current_step.next_step) || step_after(current_step)
    end
  end
end
