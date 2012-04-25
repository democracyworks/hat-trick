#= require vendor_js

class HatTrickWizard
  constructor: (formElem, @wizard) ->
    @form = $(formElem)
    fieldsets = @form.find("fieldset")
    fieldsets.addClass("step")
    wizard_buttons = '<input type="reset" /><input type="submit" />'
    fieldsets.find("div.buttons").html wizard_buttons
    window.htData = {}
    # prevent submitting the step that happens to be the last fieldset
    this.addFakeLastStep()
    this.enableFormwizard() # unless this.formwizardEnabled()
    this.setCurrentStepField()
    # TODO: Try this out instead of putting :start first
    # this.showStep(@wizard.currentStep)
    this.bindEvents()

  buttons: {}

  findStep: (stepId) ->
    @form.find("fieldset##{stepId}")

  createMethodField: (method) ->
    """<input type="hidden" name="_method" value="#{method}" />"""

  setAction: (url, method) ->
    methodLower = method.toLowerCase()
    console.log "Setting form action to #{methodLower} #{url}"
    @form.attr("action", url)
    @form.attr("method", "post")
    methodField = @form.find('input[name="_method"]')
    methodField.remove()
    if methodLower isnt "post"
      @form.prepend(this.createMethodField(method))

  currentStepId: ->
    @form.formwizard("state").currentStep

  currentStep: ->
    stepId = this.currentStepId()
    this.findStep(stepId)

  nextStepFieldHTML: """<input type="hidden" name="_ht_next_step" class="_ht_link" value="" />"""

  fieldsets: ->
    @form.find("fieldset")

  ajaxEvents: (firstStep=false) ->
    remoteAjax = {}
    $fieldsets = this.fieldsets()
    $fieldsets = $fieldsets.filter(":first") if firstStep
    $fieldsets.each (index, element) =>
      stepId = $(element).attr("id")
      remoteAjax[stepId] = this.createAjaxEvent(stepId)
    remoteAjax

  createAjaxEvent: (step) ->
    ajax =
      url: @form.attr("action"),
      dataType: "json",
      beforeSubmit: (data) =>
        console.log "Sending these data to the server: #{JSON.stringify(data)}"
      success: (data) =>
        console.log "Successful form POST; got #{JSON.stringify(data)}"
        if data.wizardMetadata?
          this.setAction(data.wizardMetadata.url, data.wizardMetadata.method)
        # merge new data with window.htData
        $.extend(window.htData, data)
      error: (data) =>
        appErrors = eval "(#{data.responseText})"
        this.addErrorItem value[0] for key, value of appErrors.formModel
    ajax

  addErrorItem: (message) ->
    $errorList = this.currentStep().find("ul.hat_trick_errors")
    if $errorList.length > 0
      $errorList.append("<li>#{message}</li>")
      $errorList.show()

  updateSteps: ->
    @form.formwizard("update_steps")
    @form.formwizard("option", remoteAjax: this.ajaxEvents())

  goToStepId: (stepId) ->
    console.log "Setting up goto #{stepId}"
    this.setHTMeta("next_step", stepId)
    @form.formwizard("next")

  repeatStep: (step) ->
    $sourceStep = this.findStep(step.repeatOf.fieldset)
    console.log "Cloning repeated step #{step.repeatOf.fieldset}"
    $clonedStep = $sourceStep.clone(true, true)
    $clonedStep.css("display", "none")
    $clonedStep.attr("id", step.name)
    $sourceStep.after($clonedStep)
    this.updateSteps()
    @form.formwizard("show", step.name)

  showStep: (step) ->
    console.log "Showing step #{step.fieldset}"
    @form.formwizard("show", step.fieldset)

  formwizardEnabled: ->
    @form.formwizard?

  addFakeLastStep: ->
    @form.append """<fieldset id="_ht_fake_last_step" style="display: none;" class="step"></fieldset>"""

  enableFormwizard: ->
    @form.formwizard
      formPluginEnabled: true,
      validationEnabled: true,
      focusFirstInput: true,
      historyEnabled: true,
      disableUIStyles: true,
      inDuration: 0,
      linkClass: "_ht_link",
      remoteAjax: this.ajaxEvents(true), # adds first Ajax event
      formOptions:
        success: (data) =>
          console.log "Successful form POST"
        beforeSubmit: (data) =>
          console.log "Sending these data to the server: #{JSON.stringify(data)}"

  htMetaHTML: (name) ->
    """<input type="hidden" name="_ht_meta[#{name}]" id="_ht_#{name}" value="" />"""

  setHTMeta: (key, value) ->
    $meta = @form.find("input:hidden#_ht_#{key}")
    if $meta.length is 0
      $meta = @form.prepend(this.htMetaHTML(key)).find("#_ht_#{key}")
    $meta.val(value)

  clearHTMeta: (key) ->
    @form.find("input:hidden#_ht_#{key}").remove()

  setCurrentStepField: ->
    stepId = this.currentStepId()
    this.setHTMeta("step", stepId)
    console.log "Current form step: #{stepId}"

  clearNextStepField: ->
    this.clearHTMeta("next_step")

  fieldRegex: /^([^\[]+)\[([^\]]+)\]$/

  setFieldValues: (formModel, selector, callback) ->
    $currentStep = this.currentStep()
    $currentStep.find(selector).each (index, element) =>
      $element = $(element)
      elementName = $element.attr("name")
      if elementName? and elementName.search(@fieldRegex) isnt -1
        [_, modelName, fieldName] = elementName.match(@fieldRegex)
        if formModel[fieldName]?
          fieldValue = formModel[fieldName]
          callback($element, fieldValue) if fieldValue?

  fillTextFields: (formModel) ->
    this.setFieldValues formModel, "input:text", ($input, value) =>
      $input.val(value)

  setSelectFields: (formModel) ->
    this.setFieldValues formModel, "select", ($select, value) =>
      $select.find("option[value=\"#{value}\"]").attr("selected", "selected")

  setCheckboxes: (formModel) ->
    this.setFieldValues formModel, "input:checkbox", ($checkbox, value) =>
      $checkbox.attr("checked", "checked") if value

  setRadioButtons: (formModel) ->
    this.setFieldValues formModel, "input:radio", ($radio, value) =>
      $radio.find("[value=\"#{value}\"]").attr("checked", "checked")

  setFormFields: (formModel) ->
    this.fillTextFields(formModel)
    this.setSelectFields(formModel)
    this.setCheckboxes(formModel)
    this.setRadioButtons(formModel)

  createButton: (name, label) ->
    """<input type="button" name="#{name}" value="#{label}" />"""

  setButton: (name, label) ->
    $buttonsDiv = this.currentStep().find("div.buttons")
    switch name
      when "next"
        console.log "Setting submit button val to #{label}"
        $buttonsDiv.find('input:submit').val(label)
      when "back"
        console.log "Setting reset button val to #{label}"
        $buttonsDiv.find('input:reset').val(label)
      else
        buttonSelector = """input:button[name="#{name}"][value="#{label}"]"""
        $existingButtons = $buttonsDiv.find(buttonSelector)
        if $existingButtons.length == 0
          console.log "Adding new #{name}:#{label} button"
          $newButton = $buttonsDiv.append(this.createButton(name, label))
          $newButton.click (event) =>
            event.preventDefault()
            this.goToStepId(name)

  bindEvents: ->
    @form.bind "step_shown", (event, data) =>
      this.setCurrentStepField()
      this.clearNextStepField()
      this.setFormFields(htData.formModel)

      buttons = this.buttons[this.currentStepId()]
      if buttons?
        this.setButton(name, label) for own name, label of buttons

      if data.previousStep is data.firstStep
        # adds additional Ajax events now that we have the update URL
        @form.formwizard("option", remoteAjax: this.ajaxEvents())

    @form.bind "after_remote_ajax", (event, data) =>
      if htData.wizardMetadata?.currentStep.buttons?
        stepId = htData.wizardMetadata.currentStep.fieldset
        this.buttons[stepId] = htData.wizardMetadata.currentStep.buttons

      if htData.wizardMetadata?.currentStep.repeatOf?
        this.repeatStep(htData.wizardMetadata.currentStep)
      else
        this.showStep(htData.wizardMetadata.currentStep)

$ ->
  $form = $("form.wizard")
  if htData? and !htWizard?
    console.log "Creating new HatTrickWizard instance"
    window.htWizard = new HatTrickWizard($form, htData.wizardMetadata)
