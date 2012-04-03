module HatTrick
  class Step
    attr_reader :callbacks, :include_data_key
    attr_accessor :name, :fieldset
    attr_writer :repeat

    def initialize(args={})
      args.each_pair do |k,v|
        setter = "#{k}="
        if respond_to?(setter)
          send(setter,v)
        end
      end
      @callbacks = {}
      @repeat = false
    end

    def name=(name)
      @name = name.to_sym
    end

    def fieldset=(fieldset)
      @fieldset = fieldset.to_sym
    end

    def fieldset
      @fieldset or @name
    end

    def repeat?
      @repeat
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
      { :name => name, :fieldset => fieldset, :repeat => repeat? }
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

    def run_before_callback!(context)
      run_callback(:before, context)
    end

    def run_include_data_callback!(context)
      run_callback(:include_data, context)
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
