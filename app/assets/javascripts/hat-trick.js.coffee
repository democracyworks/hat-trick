#= require vendor_js

class HatTrickWizard
  constructor: (formElem, @wizard) ->
    @form = $(formElem)
    this.stepShownCallback() # because we just showed the first step (or the one in the URL)

  formwizardEnabled: false

  linkClass: "_ht_link"

  buttons: []

  stepsNeedUpdate: false

  stepShownCallback: ->
    if not @formwizardEnabled
      this.addStepClass()
      this.setAction(hatTrick.metadata.url, hatTrick.metadata.method)
      # prevent submitting the step that happens to be the last fieldset
      # TODO: Figure out a better way to do this
      this.addFakeLastStep()
    this.updateStepFromMetadata()
    if not @formwizardEnabled
      currentStepId = this.currentStepId()
      # can't go back from the first step
      if hatTrick.metadata.currentStep.first
        # delete this.buttons[currentStepId]["back"]
        this.buttons[currentStepId].filter (button) ->
          not button.back?

      this.setupButtonsForStep(currentStepId)
      this.enableFormwizard()
      this.bindEvents()
    else
      this.setupButtonsForCurrentStep()
      if @stepsNeedUpdate
        this.updateSteps()
        @stepsNeedUpdate = false
      else
        this.updateButtons()
    this.setCurrentStepField()
    this.removeLinkField()
    this.setFormFields(hatTrick.model)
    this.createDummyModelField() unless this.currentStepHasModelFields()

  addStepClass: ->
    @form.find("fieldset").addClass("step")

  findStep: (stepId) ->
    @form.find("fieldset##{stepId}")

  createMethodField: (method) ->
    """<input type="hidden" name="_method" value="#{method}" />"""

  setAction: (url, method) ->
    methodLower = method.toLowerCase()
    @form.attr("action", url)
    @form.attr("method", "post")
    @form.formwizard("option", remoteAjax: this.ajaxEvents())
    methodField = @form.find('input[name="_method"]')
    methodField.remove()
    if methodLower isnt "post"
      @form.prepend(this.createMethodField(method))

  currentStepId: ->
    stepId = @form.formwizard("state").currentStep
    unless stepId? and stepId isnt ""
      stepId = hatTrick.metadata.currentStep.name
    stepId

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
        @form.trigger 'ajaxSuccess', serverData
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
        this.addErrorItem value[0] for key, value of appErrors.model when key isnt "__name__"
        this.removeLinkField()
        @form.trigger 'ajaxErrors', appErrors.model
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

  updateButtons: ->
    @form.formwizard("update_buttons")

  updateSteps: ->
    @form.formwizard("update_steps")
    @form.formwizard("option", remoteAjax: this.ajaxEvents())

  goToStepId: (stepId) ->
    this.setLinkField(stepId)
    @form.formwizard("next")

  # TODO: Try linking to the same step rather than cloning it.
  # I'm becoming more and more convinced that that won't work, however.
  # And this isn't as bad as it used to be.
  repeatStep: (step) ->
    if $("fieldset##{step.name}").length is 0
      $sourceStep = this.findStep(step.repeatOf.fieldset)
      $clonedStep = $sourceStep.clone(true, true)
      $clonedStep.css("display", "none")
      $clonedStep.attr("id", step.name)
      $sourceStep.after($clonedStep)
      this.buttons[step.name] = this.buttons[step.repeatOf.name]
      this.updateSteps()
    this.setLinkField step.name

  removeLinkField: ->
    this.currentStep().find("input.#{@linkClass}").remove()

  setLinkField: (stepId) ->
    inputId = "_ht_link_to_#{stepId}"
    this.setHiddenInput "_ht_step_link", stepId, inputId, @linkClass, this.currentStep()

  linkFieldSet: ->
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
      next: "button:submit",
      back: "button:reset",
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
    $input

  hiddenInputHTML: (name, id, classes = "") ->
    """<input type="hidden" id="#{id}" name="#{name}" class="#{classes}" value="" />"""

  setHTMeta: (key, value) ->
    this.setHiddenInput "_ht_meta[#{key}]", value, "_ht_#{key}"

  clearHTMeta: (key) ->
    @form.find("input:hidden#_ht_#{key}").remove()

  setCurrentStepField: ->
    stepId = this.currentStepId()
    this.setHTMeta("step", stepId)

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

  # TODO: DRY this up as much as possible. Radio buttons a little different
  #       than the other form controls since they share names and behave as a
  #       named group.
  setRadioButtons: (model) ->
    $currentStep = this.currentStep()
    selector = "input:radio"
    radioGroups = {}
    $currentStep.find(selector).each ->
      radioGroups[$(this).attr("name")] = true
    for radioGroup of radioGroups
      do (radioGroup) =>
        if radioGroup.search(@fieldRegex) isnt -1
          [_, modelName, fieldName] = radioGroup.match(@fieldRegex)
          if model['__name__'] is modelName and model[fieldName]?
            fieldValue = model[fieldName]
            $radioGroup = $("input:radio[name=\"#{radioGroup}\"]")
            $radioGroup.removeAttr("checked")
            $radioGroup.filter("[value=\"#{fieldValue}\"]").attr("checked", "checked")

  setFormFields: (model) ->
    # log "Setting form fields based on: #{JSON.stringify(model)}"
    this.fillTextFields(model)
    this.setSelectFields(model)
    this.setCheckboxes(model)
    this.setRadioButtons(model)

  createButtonElement: (name, value, label, type="button") ->
    $elem = $("""<button type="#{type}" class="wizard_button" name="#{name}"></button>""")
    $elem.html label
    $elem.val value
    $elem

  createButton: (toStep, button) ->
    $button = this.createButtonElement button.name, button.value, button.label
    if button.id?
      $button.attr("id", button.id)
    else
      $button.attr("id", "#{this.currentStepId()}_#{button.name}_#{button.value}")
    if button["class"]?
      $button.addClass(button["class"])
    $button.click =>
      clickCallbackData =
        currentStep: this.currentStepId()
        button: $button.attr "id"
      @form.trigger "other_button_click", clickCallbackData
    $button

  # TODO: DRY this up
  setButton: (stepId, toStep, button) ->
    $buttonsDiv = $("fieldset##{stepId}").find("div.buttons")
    switch toStep
      when "next"
        $button = $buttonsDiv.find('button.wizard_next')
        unless $button.length > 0
          $button = $('<button type="submit" class="wizard_button wizard_next" name="next"></button>').appendTo $buttonsDiv
        $button.val button.value
        $button.html button.label
        if button.id?
          $button.attr "id", button.id
        else
          $button.attr "id", "#{stepId}_next_button"
        $button.addClass button["class"] if button["class"]?
      when "back"
        $button = $buttonsDiv.find('button.wizard_back')
        unless $button.length > 0
          $button = $('<button type="reset" class="wizard_button wizard_back" name="back"></button>').appendTo $buttonsDiv
        $button.val button.value
        $button.html button.label
        if button.id?
          $button.attr "id", button.id
        else
          $button.attr "id", "#{stepId}_back_button"
        $button.addClass button["class"] if button["class"]?
      else
        buttonSelector = """button[name="#{button.name}"][value="#{button.value}"]"""
        $existingButtons = $buttonsDiv.find(buttonSelector)
        if $existingButtons.length is 0
          $newButton = $(this.createButton(toStep, button)).appendTo($buttonsDiv)
          $newButton.click (event) =>
            event.preventDefault()
            fieldId = "button_#{$newButton.attr("name")}_#{$newButton.val()}_field"
            this.setHiddenInput $newButton.attr("name"), $newButton.val(), fieldId, "", $buttonsDiv
            this.goToStepId(toStep)

  setupButtonsForCurrentStep: ->
    this.setupButtonsForStep this.currentStepId()

  setupButtonsForStep: (stepId) ->
    buttons = this.buttons[stepId]
    if buttons?
      for button in buttons
        do (button) =>
          this.setButton(stepId, toStep, buttonData) for toStep, buttonData of button

  setContents: (stepPartials) ->
    for stepName, partial of stepPartials
      do (stepName, partial) =>
        stepId = underscoreString stepName
        $partial = $(partial)
        fieldsetContents = if $partial.filter("fieldset").length > 0
          $partial.filter("fieldset").html()
        else
          $partial.find('fieldset').html()
        $step = $("fieldset##{stepId}")
        $step.html fieldsetContents
        $step.data("contents", "loaded")
        @stepsNeedUpdate = true

  handleServerData: (data) =>
    if data.metadata?.url? and data.metadata?.method?
      this.setAction(data.metadata.url, data.metadata.method)
    $.extend(window.hatTrick, data) # merge new data with hatTrick
    this.updateStepFromMetadata()

  metadataRequestCallback: (data) =>
    this.handleServerData(data)
    this.removeLinkField() # updateStepFromMetadata sets this to currentStep
    this.setupButtonsForCurrentStep()
    this.updateButtons()
    this.setFormFields(hatTrick.model)
    @form.trigger "hat_trick_step_shown", { currentStep: this.currentStepId() }

  requestMetadataFromServer: ->
    metadataUrl = document.location.pathname
    lastChar = metadataUrl.charAt(metadataUrl.length - 1)
    metadataUrl += "/" unless lastChar is "/"
    metadataUrl += "metadata"
    $.ajax
      type: "GET"
      url: metadataUrl
      success: this.metadataRequestCallback
      dataType: "json"

  updateStepContents: ->
    stepKey = camelizeString(this.currentStepId())
    if hatTrick.data?.hatTrickStepContents?[stepKey]?
      this.setContents(hatTrick.data.hatTrickStepContents)
    else
      this.requestMetadataFromServer()

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
    currentStepId = this.currentStepId()
    if $("fieldset##{currentStepId}").data("contents") is "server"
      this.updateStepContents()
    if hatTrick.metadata?.currentStep?
      this.setButtonMetadataForCurrentStep()
      this.createDummyModelField() unless this.currentStepHasModelFields()

      currentStep = hatTrick.metadata.currentStep
      if currentStep.repeatOf?
        this.repeatStep(currentStep)
      else
        this.setLinkField(currentStep.fieldset) unless this.linkFieldSet()

  bindEvents: ->
    @form.bind "step_shown", (event, data) =>
      this.stepShownCallback()
      @form.trigger "hat_trick_step_shown", data

$ ->
  if $("form.wizard").length > 0
    $form = $("form.wizard")
    window.hatTrick = {} unless window.hatTrick?
    unless window.hatTrick.wizard?
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
