module HatTrick
  module FormHelper
    def wizard_form_for(record, *args, &proc)
      options = args.extract_options!
      options[:html] = { class: "wizard" }
      controller.gon.form_model = record
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
