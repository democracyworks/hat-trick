require 'hat_trick/step'

module HatTrick
  class Wizard
    include Enumerable
    attr_accessor :current_step, :last_step, :create_url, :update_url,
                  :controller

    def initialize
      @current_form_url = :create_url
    end

    def current_form_url
      send(@current_form_url)
    end

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

    def to_ary
      [].tap do |ary|
        self.each do |step|
          ary << step
        end
      end
    end
    alias_method :steps, :to_ary
  end
end
