#= require vendor_js

class HatTrickWizard
  constructor: (formElem, @wizard) ->
    @form = $(formElem)
    @fieldsets = @form.find("fieldset")
    @fieldsets.addClass("step")
    wizard_buttons = '<input type="reset" /><input type="submit" />'
    @fieldsets.find("div.buttons").html wizard_buttons
    this.enableFormwizard() # unless this.formwizardEnabled()
    this.setCurrentStepField()
    # TODO: Try this out instead of putting :start first
    # this.showStep(@wizard.currentStep)
    this.bindEvents()

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

  createAjaxEvents: (firstStep=true) ->
    remoteAjax = {}
    $fieldsets = @fieldsets
    $fieldsets = $fieldsets.filter(":first") if firstStep
    $fieldsets.each (index, element) =>
      console.log "Adding AJAX to step #{index}"
      remoteAjax[$(element).attr("id")] =
        url: @form.attr("action"),
        dataType: "json",
        beforeSubmit: (data) =>
          console.log "Sending these data to the server: #{$.param(data)}"
        success: (data) =>
          console.log "Successful form POST; got #{$.param(data)}"
          if data.wizardMetadata?
            this.setAction(data.wizardMetadata.url, data.wizardMetadata.method)
          window.ht = data
    remoteAjax

  repeatStep: (step) ->
    $sourceStep = this.findStep(step.repeatOf.fieldset)
    console.log "Cloning repeated step #{step.repeatOf.fieldset}"
    $clonedStep = $sourceStep.clone(true)
    $clonedStep.css("display", "none")
    $clonedStep.attr("id", step.name)
    $sourceStep.after($clonedStep)
    @form.formwizard("update_steps")
    @form.formwizard("show", step.name)

  showStep: (step) ->
    console.log "Showing step #{step.fieldset}"
    @form.formwizard("show", step.fieldset)

  formwizardEnabled: ->
    @form.formwizard?

  enableFormwizard: ->
    @form.formwizard
      formPluginEnabled: true,
      validationEnabled: true,
      focusFirstInput: true,
      historyEnabled: true,
      disableUIStyles: true,
      inDuration: 0,
      linkClass: "_ht_link",
      remoteAjax: this.createAjaxEvents(), # adds first Ajax event
      formOptions:
        success: (data) =>
          console.log "Successful form POST"
        beforeSubmit: (data) =>
          console.log "Sending these data to the server: #{$.param(data)}"

  stepFieldHTML: """<input type="hidden" name="_ht_meta[step]" id="_ht_step" value="" />"""

  setCurrentStepField: ->
    $stepFields = @form.find("#_ht_step")
    $stepField = if $stepFields.length > 0
      $stepFields
    else
      @form.prepend(@stepFieldHTML).find("#_ht_step")
    stepId = this.currentStepId()
    console.log "Current form step: #{stepId}"
    $stepField.val(stepId)

  fieldRegex: /^([^\[]+)\[([^\]]+)\]$/

  setFieldValues: (formModel, selector, callback) ->
    $currentStep = this.currentStep()
    $currentStep.find(selector).each (index, element) =>
      $element = $(element)
      elementName = $element.attr("name")
      if elementName? and elementName.search(@fieldRegex) isnt -1
        [_, modelName, fieldName] = elementName.match(@fieldRegex)
        if formModel[modelName]? and formModel[modelName][fieldName]?
          fieldValue = formModel[modelName][fieldName]
          callback($element, fieldValue) if fieldValue?

  fillTextFields: (formModel) ->
    this.setFieldValues formModel, "input:text", ($input, value) =>
      $input.val(value)

  setSelectFields: (formModel) ->
    this.setFieldValues formModel, "select", ($select, value) =>
      $select.find("option[value=#{value}]").attr("selected", "selected")

  setCheckboxes: (formModel) ->
    this.setFieldValues formModel, "input:checkbox", ($checkbox, value) =>
      $checkbox.attr("checked", "checked") if value

  setRadioButtons: (formModel) ->
    this.setFieldValues formModel, "input:radio", ($radio, value) =>
      $radio.find("[value=#{value}]").attr("checked", "checked")

  setFormFields: (formModel) ->
    this.fillTextFields(formModel)
    this.setSelectFields(formModel)
    this.setCheckboxes(formModel)
    this.setRadioButtons(formModel)

  bindEvents: ->
    @form.bind "step_shown", (event, data) =>
      this.setCurrentStepField()
      this.setFormFields(ht.formModel)

      if data.previousStep is data.firstStep
        console.log "Adding additional Ajax events"
        # adds additional Ajax events now that we have the update URL
        @form.formwizard("option", remoteAjax: this.createAjaxEvents(false))

    @form.bind "after_remote_ajax", (event, data) =>
      if ht.wizardMetadata.currentStep.repeatOf?
        this.repeatStep(ht.wizardMetadata.currentStep)
      else
        this.showStep(ht.wizardMetadata.currentStep)

$ ->
  $form = $("form.wizard")
  if ht? and !htWizard?
    console.log "Creating new HatTrickWizard instance"
    window.htWizard = new HatTrickWizard($form, ht.wizardMetadata)
