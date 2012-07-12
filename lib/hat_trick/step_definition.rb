module HatTrick
  class StepDefinition
    attr_reader :callbacks, :include_data_key
    attr_accessor :name, :fieldset, :buttons, :repeat_of
    attr_writer :skipped, :first

    def initialize(args={})
      args.each_pair do |k,v|
        setter = "#{k}="
        if respond_to?(setter)
          send(setter,v)
        end
      end
      @callbacks = {}
      @buttons = {
        next: default_next_button,
        back: default_back_button
      }
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

    def default_next_button
      { label: default_next_button_label }
    end

    def default_back_button
      { label: default_back_button_label }
    end

    def default_next_button_label
      begin
        label = I18n.t("wizard.buttons.next", :default => "Next")
      rescue NameError
        label = "Next"
      end
      label
    end

    def default_back_button_label
      begin
        label = I18n.t("wizard.buttons.back", :default => "Back")
      rescue NameError
        label = "Back"
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
        buttons.delete(:next)
      else
        buttons[:next] = default_next_button
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

    def page_title
      begin
        title = I18n.t("wizard.page_titles.#{name}")
      rescue NameError
        title = name.to_s.humanize
      end
      title
    end

    def as_json(options = nil)
      json = { :name => name, :fieldset => fieldset }
      json[:repeatOf] = repeat_of.as_json if repeat?
      json[:buttons] = buttons.empty? ? {} : buttons
      json[:pageTitle] = page_title
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

    def run_before_callback(context, model)
      run_callback(:before, context, model)
    end

    def run_include_data_callback(context, model)
      run_callback(:include_data, context, model)
    end

    def run_after_callback(context, model)
      run_callback(:after, context, model)
    end

    protected

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
  end
end
