#= require vendor_js

class HatTrickWizard
  constructor: (formElem, @wizard) ->
    @form = $(formElem)
    @fieldsets = @form.find("fieldset")
    @fieldsets.addClass("step")
    wizard_buttons = '<input type="reset" /><input type="submit" />'
    @fieldsets.find("div.buttons").html wizard_buttons
    this.setAction(@wizard.url, @wizard.method)
    this.enableFormwizard() # unless this.formwizardEnabled()
    this.setCurrentStepField()
    this.linkNextStep(@wizard.nextStep)
    this.bindEvents()

  findStep: (stepId) ->
    @form.find("fieldset##{stepId}")

  setAction: (url, method) ->
    console.log "Setting form action to #{method} #{url}"
    @form.attr("action", url)
    @form.attr("method", method)

  currentStepId: ->
    @form.formwizard("state").currentStep

  currentStep: ->
    stepId = this.currentStepId()
    this.findStep(stepId)

  nextStepFieldHTML: """<input type="hidden" name="_ht_next_step" class="_ht_link" value="" />"""

  linkNextStep: (nextStep) ->
    $currentStep = this.currentStep()
    if nextStep.repeat
      console.log "Cloning repeated step #{nextStep.fieldset}"
      $clonedStep = $currentStep.clone()
      $clonedStep.css("display", "none")
      $clonedStep.attr("id", "#{nextStep.name}")
      $currentStep.after($clonedStep)
      @form.formwizard("update_steps")
    else
      console.log "Linking form step to #{nextStep.fieldset}"
      $stepLinks = $currentStep.find("input._ht_link")
      $stepLink = if $stepLinks.length > 0
        $stepLinks
      else
        $currentStep.append(@nextStepFieldHTML).find("input._ht_link")
      $stepLink.val(nextStep)

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
      this.linkNextStep(ht.wizardMetadata.nextStep)
      this.setFormFields(ht.formModel)

      if data.previousStep is data.firstStep
        console.log "Adding additional Ajax events"
        # adds additional Ajax events now that we have the update URL
        @form.formwizard("option", remoteAjax: this.createAjaxEvents(false))

$ ->
  $form = $("form.wizard")
  if ht? and !htWizard?
    console.log "Creating new HatTrickWizard instance"
    window.htWizard = new HatTrickWizard($form, ht.wizardMetadata)
