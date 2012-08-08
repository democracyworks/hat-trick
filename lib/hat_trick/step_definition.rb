module HatTrick
  class StepDefinition
    attr_reader :callbacks, :include_data_key, :buttons
    attr_accessor :name, :fieldset, :wizard
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

    def default_button(type)
      { :label => button_label(type), :default => true }
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

    def add_button(button)
      buttons.delete_if do |b|
        b.keys.first == button.keys.first && b[b.keys.first][:default]
      end
      buttons << button
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

    def first?
      @first
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

    def before_callbacks
      before_callbacks = [callbacks[:before]]
      if wizard.before_callback_for_all_steps
        before_callbacks << wizard.before_callback_for_all_steps
      end
      before_callbacks
    end

    def run_before_callback(context, model)
      run_callbacks(before_callbacks, context, model)
    end

    def run_include_data_callback(context, model)
      run_callbacks([callbacks[:include_data]], context, model)
    end

    def after_callbacks
      after_callbacks = [callbacks[:after]]
      if wizard.after_callback_for_all_steps
        after_callbacks << wizard.after_callback_for_all_steps
      end
      after_callbacks
    end

    def run_after_callback(context, model)
      run_callbacks(after_callbacks, context, model)
    end

    private

    def run_callbacks(callbacks, context, model)
      result = nil
      callbacks.each do |callback|
        if callback && callback.is_a?(Proc)
          if callback.arity > 0
            unless model.is_a?(ActiveModel::Errors)
              result = context.instance_exec model, &callback
            end
          else
            result = context.instance_eval &callback
          end
        end
      end

      # return the last result; mainly for include_data
      result
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
