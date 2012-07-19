module HatTrick
  class StepDefinition
    attr_reader :callbacks, :include_data_key, :buttons
    attr_accessor :name, :fieldset, :repeat_of, :wizard
    attr_writer :skipped, :first

    delegate :config, :to => :wizard

    def initialize(args={})
      args.each_pair do |k,v|
        setter = "#{k}="
        if respond_to?(setter)
          send(setter,v)
        end
      end
      @callbacks = {}
      @buttons = [
        { next: default_button(:next) },
        { back: default_button(:back) }
      ]
      @skipped ||= false
      @last ||= false
      @first ||= false
    end

    def initialize_copy(source)
      @callbacks = {}
      @buttons = source.buttons.dup
      @skipped = false
      @last = false
      @first = false
      @repeat_of = source
    end

    def default_button(type)
      { label: button_label(type) }
    end

    def button_label(type)
      config.send("#{type}_button_label") or default_button_label(type)
    end

    def default_button_label(type)
      default_label = type.to_s.humanize
      begin
        label = I18n.t("wizard.buttons.#{type}", :default => default_label)
      rescue NameError
        label = default_label
      end
      label
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

    def last=(_last)
      @last = _last
      if @last
        buttons.delete_if { |b| b.keys.include?(:next) }
      else
        buttons << { :next => default_next_button }
      end
    end

    def last?
      @last
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
      json[:buttons] = buttons.empty? ? [] : buttons
      json[:first] = @first
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

    def include_data(context, model)
      inc_data = run_include_data_callback(context, model)
      return {} unless inc_data.respond_to?(:as_json)
      key = include_data_key.to_s.camelize(:lower)
      { key => camelize_hash_keys(inc_data) }
    end

    def run_before_callback(context, model)
      run_callback(:before, context, model)
    end

    def run_include_data_callback(context, model)
      run_callback(:include_data, context, model)
    end

    def run_after_callback(context, model)
      run_callback(:after, context, model)
    end

    private

    def run_callback(type, context, model)
      callback = callbacks[type.to_sym]
      if callback && callback.is_a?(Proc)
        if callback.arity > 0
          unless model.is_a?(ActiveModel::Errors)
            context.instance_exec model, &callback
          end
        else
          context.instance_eval &callback
        end
      end
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
