module HatTrick
  class Step
    include Comparable

    attr_reader :callbacks
    attr_accessor :name, :fieldset, :next_step, :previous_step

    def initialize(args={})
      args.each_pair do |k,v|
        setter = "#{k}="
        if respond_to?(setter)
          send(setter,v)
        end
      end
      @callbacks = {}
    end

    def name=(name)
      @name = name.to_sym
    end

    def to_s
      str = "<HatTrick::Step :#{name}"
      str += " fieldset: #{fieldset}" if fieldset != name
      str += ">"
      str
    end

    def <=>(other)
      if self.before?(other)
        -1
      elsif self.after?(other)
        1
      elsif self.equal? other
        0
      else
        raise ArgumentError, "Can't compare steps not in the same wizard"
      end
    end

    def before?(other)
      step = self
      until (step = step.next_step).nil?
        return true if step.equal? other
      end
      false
    end

    def after?(other)
      step = self
      until (step = step.previous_step).nil?
        return true if step.equal? other
      end
      false
    end

    def before_callback=(blk)
      callbacks[:before] = blk
    end

    def after_callback=(blk)
      callbacks[:after] = blk
    end

    def run_before_callback!(context)
      run_callback(:before, context)
    end

    def run_after_callback!(context)
      run_callback(:after, context)
    end

    protected

    def run_callback(type, context)
      callback = callbacks[type.to_sym]
      if callback && callback.is_a?(Proc)
        context.instance_eval &callback
      end
    end
  end
end
