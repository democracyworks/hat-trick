require 'hat_trick/step'
require 'hat_trick/controller_hooks'

module HatTrick
  class Wizard
    include Enumerable
    attr_accessor :current_step, :first_step, :last_step, :controller, :model

    def each
      step = current_step
      until step.nil?
        yield step
        step = step.next_step
      end
    end
    alias_method :each_step, :each

    def empty?
      current_step.nil?
    end

    def add_step(step, args={})
      if step.is_a?(HatTrick::Step)
        new_step = step
      else
        new_step = Step.new(name: step)
        new_step.fieldset = args[:fieldset] ? args[:fieldset] : new_step.name
      end

      if empty?
        self.current_step = new_step
        self.first_step   = new_step
      else
        new_step.previous_step = last_step
        last_step.next_step = new_step
      end
      self.last_step = new_step
      new_step
    end

    def delete_step(step)
      replace_step(step)
      step
    end

    def replace_step(old, replacement=nil)
      old_step = find_step(old)
      before_step = old_step.previous_step
      after_step = old_step.next_step
      if replacement
        if replacement.is_a?(HatTrick::Step)
          new_step = replacement
        else
          new_step = Step.new(name: replacement)
        end
        new_next = new_step
        new_previous = new_step
      else
        new_next = after_step
        new_previous = before_step
      end
      before_step.next_step = new_next
      after_step.previous_step = new_previous
      true
    end

    def find_step(step)
      if step.is_a?(HatTrick::Step)
        find { |s| s.equal? step }
      else
        find { |s| s.name == step.to_sym }
      end
    end

    def model_created?
      !(model.nil? || model.new_record?)
    end

    def current_form_url
      model_created? ? update_url : create_url
    end

    def current_form_method
      model_created? ? 'put' : 'post'
    end

    def to_ary
      [].tap do |ary|
        self.each do |step|
          ary << step
        end
      end
    end
    alias_method :steps, :to_ary

    def controller=(controller)
      unless @controller
        @controller = controller
        alias_action_methods!
      end
      @controller
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

    private

    def alias_action_methods!
      action_methods = controller.action_methods.reject do |m|
        /^render/ =~ m.to_s
      end
      HatTrick::ControllerHooks.def_action_method_aliases!(action_methods)
      action_methods.each do |meth|
        controller.class.send(:alias_method_chain, meth, :hat_trick)
      end
    end
  end
end
