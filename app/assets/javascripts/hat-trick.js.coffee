#= require vendor_js

class HatTrickWizard
  constructor: (formElem, @wizard) ->
    @form = $(formElem)
    this.stepShownCallback() # because we just showed the first step (or the one in the URL)

  formwizardEnabled: false

  linkClass: "_ht_link"

  buttons: {}

  stepsNeedUpdate: false

  stepShownCallback: ->
    if not @formwizardEnabled
      this.addStepClass()
      # prevent submitting the step that happens to be the last fieldset
      # TODO: Figure out a better way to do this
      this.addFakeLastStep()
      this.addDefaultButtons()
    this.updateStepFromMetadata()
    if not @formwizardEnabled
      this.setupButtonsForAllSteps()
      this.enableFormwizard() # this clobbers our button customizations for the current step
      this.setupButtonsForCurrentStep() # so we run this to reconfigure it
      this.bindEvents()
    else
      this.setupButtonsForCurrentStep()
      # this must be run here & after setupButtonsForCurrentStep() to support setContents()
      if @stepsNeedUpdate
        this.updateSteps()
        @stepsNeedUpdate = false
    this.setCurrentStepField()
    this.clearNextStepField()
    this.setFormFields(hatTrick.model)
    this.createDummyModelField() unless this.currentStepHasModelFields()

  addStepClass: ->
    @form.find("fieldset").addClass("step")

  addDefaultButtons: ($scope = @form.find("fieldset")) ->
    hatTrick = this
    $scope.each (index) ->
      id = $(this).attr('id')
      buttons =
        next:
          id: "#{id}_next_button"
          label: "Next"
      if index > 0 or hatTrick.formwizardEnabled
        buttons['back'] =
          id: "#{id}_back_button"
          label: "Back"
  
      hatTrick.buttons[id] = buttons
  
  findStep: (stepId) ->
    @form.find("fieldset##{stepId}")

  createMethodField: (method) ->
    """<input type="hidden" name="_method" value="#{method}" />"""

  setAction: (url, method) ->
    methodLower = method.toLowerCase()
    # log "Setting form action to #{methodLower} #{url}"
    @form.attr("action", url)
    @form.attr("method", "post")
    @form.formwizard("option", remoteAjax: this.ajaxEvents())
    methodField = @form.find('input[name="_method"]')
    methodField.remove()
    if methodLower isnt "post"
      @form.prepend(this.createMethodField(method))

  currentStepId: ->
    @form.formwizard("state").currentStep

  currentStep: ->
    stepId = this.currentStepId()
    this.findStep(stepId)

  fieldsets: ->
    @form.find("fieldset")

  ajaxEvents: ->
    remoteAjax = {}
    $fieldsets = this.fieldsets()
    $fieldsets.each (index, element) =>
      stepId = $(element).attr("id")
      remoteAjax[stepId] = this.createAjaxEvent(stepId)
    remoteAjax

  createAjaxEvent: (step) ->
    ajax =
      url: @form.attr("action")
      dataType: "json"
      # beforeSubmit: (data) =>
      #   log "Sending these data to the server: #{JSON.stringify data}"
      success: (serverData) =>
        this.handleServerData serverData
        # log "Successful form POST; got #{JSON.stringify(serverData)}"
      error: (event, status, errorThrown) =>
        log "Error response: #{event.status} #{status} - #{errorThrown} - #{event.responseText}"
        try
          appErrors = eval "(#{event.responseText})"
        catch err
          appErrors =
            model:
              unknown: [
                "There was an error communicating with the server. TurboVote staff have been notified."
              ]
        this.clearErrors()
        this.addErrorItem value[0] for key, value of appErrors.model
    ajax

  getErrorListElement: ->
    this.currentStep().find("ul.hat_trick_errors")

  clearErrors: ->
    $errorList = this.getErrorListElement()
    $errorList.hide()
    $errorList.empty()

  addErrorItem: (message) ->
    $errorList = this.getErrorListElement()
    if $errorList.length > 0
      $errorList.append("<li>#{message}</li>")
      $errorList.show()

  updateSteps: ->
    @form.formwizard("update_steps")
    @form.formwizard("option", remoteAjax: this.ajaxEvents())

  goToStepId: (stepId) ->
    this.setLinkField(stepId)
    @form.formwizard("next")

  # TODO: Try linking to the same step rather than cloning it.
  # I'm becoming more and more convinced that that won't work, however. And this isn't as bad as it used to be.
  repeatStep: (step) ->
    if $("fieldset##{step.name}").length is 0
      $sourceStep = this.findStep(step.repeatOf.fieldset)
      $clonedStep = $sourceStep.clone(true, true)
      $clonedStep.css("display", "none")
      $clonedStep.attr("id", step.name)
      $sourceStep.after($clonedStep)
      this.updateSteps()
    this.setLinkField step.name

  removeLinkField: ->
    this.currentStep().find("input.#{@linkClass}").remove()

  setLinkField: (stepId) ->
    inputId = "_ht_link_to_#{stepId}"
    this.setHiddenInput "_ht_step_link", stepId, inputId, @linkClass, this.currentStep()

  LinkFieldSet: ->
    this.currentStep().find("input[name='_ht_step_link']").length > 0

  addFakeLastStep: ->
    @form.append """<fieldset id="_ht_fake_last_step" style="display: none;" class="step"></fieldset>"""

  enableFormwizard: ->
    @form.formwizard
      formPluginEnabled: true,
      validationEnabled: false,
      focusFirstInput: true,
      historyEnabled: true,
      disableUIStyles: true,
      inDuration: 0,
      linkClass: ".#{@linkClass}",
      remoteAjax: this.ajaxEvents(),
      firstStep: hatTrick.metadata.currentStep.name
    this.formwizardEnabled = true

  setHiddenInput: (name, value, id, classes = "", scope = @form) ->
    $scope = $(scope)
    $input = $scope.find("""input##{id}[name="#{name}"]""")
    if $input.length is 0
      $input = $(this.hiddenInputHTML(name, id, classes)).prependTo $scope
    $input.val value

  hiddenInputHTML: (name, id, classes = "") ->
    """<input type="hidden" id="#{id}" name="#{name}" class="#{classes}" value="" />"""

  setHTMeta: (key, value) ->
    this.setHiddenInput "_ht_meta[#{key}]", value, "_ht_#{key}"

  clearHTMeta: (key) ->
    @form.find("input:hidden#_ht_#{key}").remove()

  setCurrentStepField: ->
    stepId = this.currentStepId()
    this.setHTMeta("step", stepId)

  # TODO: See if we still need this "next_step" ht_meta field.
  clearNextStepField: ->
    this.clearHTMeta("next_step")
    this.removeLinkField()

  fieldRegex: /^([^\[]+)\[([^\]]+)\]$/

  setFieldValues: (model, selector, callback) ->
    $currentStep = this.currentStep()
    $currentStep.find(selector).each (index, element) =>
      $element = $(element)
      elementName = $element.attr("name")
      if elementName? and elementName.search(@fieldRegex) isnt -1
        [_, modelName, fieldName] = elementName.match(@fieldRegex)
        if model['__name__'] is modelName and model[fieldName]?
          fieldValue = model[fieldName]
          callback($element, fieldValue) if fieldValue?

  fillTextFields: (model) ->
    this.setFieldValues model, "input:text", ($input, value) =>
      $input.val(value)

  setSelectFields: (model) ->
    this.setFieldValues model, "select", ($select, value) =>
      $select.find("option[value=\"#{value}\"]").attr("selected", "selected")

  setCheckboxes: (model) ->
    this.setFieldValues model, "input:checkbox", ($checkbox, value) =>
      $checkbox.attr("checked", "checked") if value

  setRadioButtons: (model) ->
    this.setFieldValues model, "input:radio", ($radio, value) =>
      $radio.find("[value=\"#{value}\"]").attr("checked", "checked")

  setFormFields: (model) ->
    # log "Setting form fields based on: #{JSON.stringify(model)}"
    this.fillTextFields(model)
    this.setSelectFields(model)
    this.setCheckboxes(model)
    this.setRadioButtons(model)

  createButton: (name, button) ->
    $button = $("""<input type="button" class="wizard_button" name="#{name}" value="#{button.label}" />""")
    if button.id?
      $button.attr("id", button.id)
    else
      $button.attr("id", "#{this.currentStepId()}_#{name}_#{button.label}")
    $button.click =>
      clickCallbackData =
        currentStep: this.currentStepId()
        button: $button.attr "id"
      @form.trigger "other_button_click", clickCallbackData
    $button

  setButton: (stepId, name, button) ->
    # log "Setting button for #{stepId} named #{name} to #{JSON.stringify(button)}"
    $buttonsDiv = $("fieldset##{stepId}").find("div.buttons")
    switch name
      when "next"
        # log "Setting #{stepId} submit button val to #{button.label}"
        $button = $buttonsDiv.find('input:submit')
        unless $button.length > 0
          $button = $('<input class="wizard_button wizard_next" type="submit" />').appendTo $buttonsDiv
        $button.val(button.label)
        $button.attr("id", button.id) if button.id?
      when "back"
        # log "Setting reset button val to #{button.label}"
        $button = $buttonsDiv.find('input:reset').val(button.label)
        unless $button.length > 0
          $button = $('<input class="wizard_button wizard_back" type="reset" />').appendTo $buttonsDiv
        $button.val(button.label)
        $button.attr("id", button.id) if button.id?
      else
        buttonSelector = """input:button[name="#{name}"][value="#{button.label}"]"""
        $existingButtons = $buttonsDiv.find(buttonSelector)
        if $existingButtons.length is 0
          # log "Adding new #{name}:#{button.label} button"
          $newButton = $(this.createButton(name, button)).appendTo($buttonsDiv)
          $newButton.click (event) =>
            event.preventDefault()
            this.goToStepId(name)

  setupButtonsForAllSteps: ->
    this.setupButtonsForStep $(fieldset).attr('id') for fieldset in $('fieldset')

  setupButtonsForCurrentStep: ->
    this.setupButtonsForStep this.currentStepId()

  setupButtonsForStep: (stepId) ->
    buttons = this.buttons[stepId]
    if buttons?
      this.setButton(stepId, name, button) for name, button of buttons

  setContents: (stepPartials) ->
    for stepName, partial of stepPartials
      do (stepName, partial) =>
        stepId = underscoreString stepName
        $partial = $(partial)
        fieldsetContents = $partial.find('fieldset').html()
        $step = $("fieldset##{stepId}")
        $step.html fieldsetContents
        this.addDefaultButtons($step)
        @stepsNeedUpdate = true

  handleServerData: (data) ->
    if data.metadata?
      this.setAction(data.metadata.url, data.metadata.method)
    $.extend(window.hatTrick, data) # merge new data with hatTrick
    this.updateStepFromMetadata()

  updateStepContents: ->
    this.setContents(hatTrick.data.hatTrickStepContents)

  setButtonMetadataForCurrentStep: ->
    if hatTrick.metadata?.currentStep?
      currentStep = hatTrick.metadata.currentStep
      if currentStep.buttons?
        stepId = currentStep.fieldset
        this.buttons[stepId] = currentStep.buttons

  modelName: ->
    hatTrick.model['__name__']

  createDummyModelField: ->
    this.setHiddenInput "#{this.modelName()}[_dummy]", "1"

  currentStepHasModelFields: ->
    this.currentStep().find("input[name^='#{this.modelName()}[']").length > 0

  updateStepFromMetadata: ->
    if hatTrick.metadata?.currentStep?
      this.updateStepContents() if hatTrick.data.hatTrickStepContents?
      this.setButtonMetadataForCurrentStep()
      this.createDummyModelField() unless this.currentStepHasModelFields()

      currentStep = hatTrick.metadata.currentStep
      if currentStep.repeatOf?
        this.repeatStep(currentStep)
      else
        this.setLinkField(currentStep.fieldset) unless this.LinkFieldSet()

  bindEvents: ->
    @form.bind "step_shown", (event, data) =>
      this.stepShownCallback()

$ ->
  if $("form.wizard").length > 0
    $form = $("form.wizard")
    window.hatTrick = {} unless window.hatTrick?
    unless window.hatTrick.wizard?
      # log "Creating new HatTrickWizard instance"
      window.hatTrick.wizard = new HatTrickWizard($form, hatTrick.metadata)

camelizeString = (string) ->
  re = /_([^_]*)/g
  while matches = re.exec(string)
    result = string.slice(0, matches.index) unless result?
    result += "#{matches[1][0].toUpperCase()}#{matches[1].slice(1)}"
  result = string unless result?
  result

underscoreString = (string) ->
  re = /([A-Z]+)([a-z\d]+)/g
  while matches = re.exec(string)
    result = string.slice(0, matches.index) unless result?
    result += "_#{matches[1].toLowerCase()}#{matches[2]}"
  result = string unless result?
  result

log = (msg) ->
  if window['console']?
    console.log msg
