module HatTrick
  class StepDefinition
    attr_reader :callbacks, :include_data_key
    attr_accessor :name, :fieldset, :buttons, :repeat_of
    attr_writer :skipped

    def initialize(args={})
      args.each_pair do |k,v|
        setter = "#{k}="
        if respond_to?(setter)
          send(setter,v)
        end
      end
      @callbacks = {}
      @buttons = {}
      @skipped = false
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

    def skipped?
      @skipped
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

    def camelize_hash_keys(_hash)
      hash = {}
      _hash.each do |k,v|
        hash[k.to_s.camelize(:lower)] = v
      end
      hash
    end

    def as_json(options = nil)
      json = { :name => name, :fieldset => fieldset }
      json[:repeatOf] = repeat_of.as_json if repeat?
      json[:buttons] = buttons unless buttons.empty?
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

    def run_before_callback(context, wizard_dsl, model)
      run_callback(:before, context, wizard_dsl, model)
    end

    def run_include_data_callback(context, wizard_dsl, model)
      run_callback(:include_data, context, wizard_dsl, model)
    end

    def run_after_callback(context, wizard_dsl, model)
      run_callback(:after, context, wizard_dsl, model)
    end

    protected

    def run_callback(type, context, *args)
      callback = callbacks[type.to_sym]
      if callback && callback.is_a?(Proc)
        if callback.arity > 1
          context.instance_exec args[0], args[1], &callback
        elsif callback.arity == 1
          context.instance_exec args[0], &callback
        else
          context.instance_eval &callback
        end
      end
    end
  end
end
