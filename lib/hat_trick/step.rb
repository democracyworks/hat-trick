module HatTrick
  class Step
    attr_reader :callbacks, :include_data_key
    attr_accessor :name, :fieldset, :repeat_of

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

    def fieldset=(fieldset)
      @fieldset = fieldset.to_sym
    end

    def fieldset
      @fieldset or name
    end

    def repeat?
      !repeat_of.nil?
    end

    def to_s
      str = "<HatTrick::Step:0x%08x :#{name}" % (object_id * 2)
      str += " fieldset: #{fieldset}" if fieldset != name
      str += ">"
      str
    end

    def to_sym
      name.to_sym
    end

    def as_json(options = nil)
      json = { :name => name, :fieldset => fieldset }
      json[:repeatOf] = repeat_of.as_json if repeat?
      json
    end

    def before_callback=(blk)
      callbacks[:before] = blk
    end

    def after_callback=(blk)
      callbacks[:after] = blk
    end

    def include_data=(hash)
      callbacks[:include_data] = hash.values.first
      @include_data_key = hash.keys.first
    end

    def run_before_callback!(context, wizard_dsl)
      run_callback(:before, context, wizard_dsl)
    end

    def run_include_data_callback!(context, model)
      run_callback(:include_data, context, model)
    end

    def run_after_callback!(context, wizard_dsl)
      run_callback(:after, context, wizard_dsl)
    end

    protected

    def run_callback(type, context, arg)
      callback = callbacks[type.to_sym]
      if callback && callback.is_a?(Proc)
        if callback.arity > 0
          context.instance_exec arg, &callback
        else
          context.instance_eval &callback
        end
      end
    end
  end
end
