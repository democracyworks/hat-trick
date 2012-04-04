module HatTrick
  module FormHelper
    def wizard_form_for(record, *args, &proc)
      options = args.extract_options!
      options[:html] = { :class => 'wizard' }

      wizard = controller.send(:ht_wizard)

      # Do we still need these 2 lines?
      wizard.model = record
      controller.gon.form_model = record

      options[:url] = wizard.current_form_url
      options[:method] = wizard.current_form_method.to_sym

      output = ActiveSupport::SafeBuffer.new
      output.safe_concat(wizard_partial)

      # now run the default FormBuilder & append to output
      output << self.form_for(record, *(args << options), &proc)
    end

    private

    def wizard_partial
      controller.render_to_string(:partial => 'hat_trick/wizard_meta')
    end
  end
end
