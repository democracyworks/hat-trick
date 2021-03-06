#= require vendor_js

class HatTrickWizard
  constructor: (formElem, @wizard) ->
    @form = $(formElem)
    this.enableFormwizard()

  debug: ->
    window.hatTrick.railsEnv == "development"

  linkClass: "_ht_link"

  buttons: []

  stepsNeedUpdate: false

  stepShownCallback: ->
    currentStepId = this.currentStepId()

    @lastButtonChanged = null

    if hatTrick.stepMetadata[currentStepId]?
      hatTrick.metadata.currentStep = hatTrick.stepMetadata[currentStepId]
    else
      this.requestMetadataFromServer()
      return

    this.updateStepFromMetadata()
    currentStepId = this.currentStepId()
    # can't go back from the first step
    if hatTrick.metadata.currentStep.first
      this.buttons[currentStepId] = this.buttons[currentStepId].filter (button) ->
        not button.back?
    this.setupButtonsForCurrentStep()
    if @stepsNeedUpdate
      this.updateSteps()
      @stepsNeedUpdate = false
    else
      this.updateButtons()
    this.removeLinkFields()
    this.setFormFields(hatTrick.model)
    this.createDummyModelField() unless this.currentStepHasModelFields()
    @form.trigger 'step_changed', { currentStep: this.currentStepId() }

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
      beforeSerialize: (form, options) =>
        if options.data._ht_step_link == this.currentStepId()
          log "Warning: Tried to link to the current step; this is probably not what you want."
        return true;
      # beforeSubmit: (data) =>
      #   log "Sending these data to the server: #{JSON.stringify data}"
      success: (serverData) =>
        this.clearErrors()
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
            status: status
            event: event
        this.clearErrors()
        this.addErrorItem value[0] for key, value of appErrors.model when key isnt "__name__"
        this.removeLinkFields()
        @form.trigger 'ajaxErrors', appErrors
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

  removeLinkFields: ->
    @form.find("input.#{@linkClass}").remove()

  setLinkField: (stepId) ->
    inputId = "_ht_link_to_#{stepId}"
    this.setHiddenInput "_ht_step_link", stepId, inputId, @linkClass, this.currentStep()

  linkFieldSet: ->
    this.currentStep().find("input[name='_ht_step_link']").length > 0

  addFakeLastStep: ->
    @form.append """<fieldset id="_ht_fake_last_step" style="display: none;" class="step"></fieldset>"""

  enableFormwizard: ->
    this.addStepClass()
    this.saveStepMetadata()
    this.setAction(hatTrick.metadata.url, hatTrick.metadata.method)
    # prevent submitting the step that happens to be the last fieldset
    # TODO: Figure out a better way to do this
    this.addFakeLastStep()
    this.bindEvents()
    firstStep = if hatTrick.metadata.currentStep?.redirect
      hatTrick.metadata.currentStep.redirectFrom
    else
      hatTrick.metadata.currentStep.fieldset
    @form.formwizard
      formPluginEnabled: true,
      validationEnabled: false,
      focusFirstInput: true,
      disableUIStyles: true,
      outDuration: 200,
      inDuration: 10, # don't set this to 0 or step_shown will be triggered too early
      next: "button:submit",
      back: "button:reset",
      linkClass: ".#{@linkClass}",
      remoteAjax: this.ajaxEvents(),
      firstStep: firstStep
    # see if we got a redirect & follow if so
    currentStepId = this.currentStepId()
    if hatTrick.metadata.currentStep?
      currentStepData = hatTrick.metadata.currentStep
      if currentStepData.redirect and currentStepData.redirectFrom is currentStepId
        @form.formwizard("redirect", currentStepData.fieldset)

  setHiddenInput: (name, value, id, classes = "", scope = @form) ->
    $scope = $(scope)
    $input = $scope.find("""input[name="#{name}"]""")
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
    this.fillTextFields(model)
    this.setSelectFields(model)
    this.setCheckboxes(model)
    this.setRadioButtons(model)

  createButtonElement: (name, value, label, type="button") ->
    $elem = $("""<button type="#{type}" class="wizard_button"></button>""")
    $elem.attr "name", name if name?
    $elem.html label
    $elem.val value if value?
    $elem

  createButton: (toStep, button) ->
    switch toStep
      when "next"
        if button.class is ""
          button.class = "wizard_next"
        else
          button["class"] += " wizard_next"
        type = "submit"
      when "back"
        if button.class is ""
          button.class = "wizard_back"
        else
          button["class"] += " wizard_back"
        button.name = "back"
        unless button.id?
          button.id = "#{this.currentStepId()}_back_button"
        delete button["value"]
        type = "reset"
      else
        type = "button"
    $button = this.createButtonElement button.name, button.value, button.label, type
    if button.id?
      $button.attr("id", button.id)
    else if button.name? and button.value?
      $button.attr("id", "#{this.currentStepId()}_#{button.name}_#{button.value}")
    if button["class"]?
      $button.addClass(button["class"])
    $button

  setButton: (stepId, toStep, button) ->
    $buttonsDiv = $("fieldset##{stepId}").find("div.buttons")
    if $buttonsDiv.find("button").length > 0
      @lastButtonChanged ?= $buttonsDiv.find("button:first")
    buttonSelector = """button[name="#{button.name}"][value="#{button.value}"]"""
    $existingButtons = $buttonsDiv.find(buttonSelector)
    if $existingButtons.length is 0
      $newButton = $(this.createButton(toStep, button))
      if @lastButtonChanged?
        @lastButtonChanged.after $newButton
      else
        $buttonsDiv.append $newButton
      @lastButtonChanged = $newButton
      unless toStep is "next" or toStep is "back"
        $newButton.click (event) =>
          event.preventDefault()
          fieldId = "button_#{$newButton.attr("name")}_#{$newButton.val()}_field"
          this.setHiddenInput $newButton.attr("name"), $newButton.val(), fieldId, "", $buttonsDiv
          this.goToStepId(toStep)

  setupButtonsForCurrentStep: ->
    $currentStep = this.currentStep()
    $buttonsDiv = $currentStep.find("div.buttons")
    $buttons = $buttonsDiv.find("button")
    unless $buttonsDiv.data "buttonsAdded"
      this.setupButtonsForStep this.currentStepId()

  setupButtonsForStep: (stepId) ->
    buttons = this.buttons[stepId]
    if buttons?
      for button in buttons
        do (button) =>
          this.setButton(stepId, toStep, buttonData) for toStep, buttonData of button
    $("##{stepId} div.buttons").data "buttonsAdded", true

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
        $step.filter("fieldset:not(.no-focus)").find(":input:not(input[type=hidden]):first").focus();
        $step.data("contents", "loaded")
        @stepsNeedUpdate = true

  saveStepMetadata: (stepId=this.currentStepId(), metadata=hatTrick.metadata.currentStep) ->
    hatTrick.stepMetadata = {} unless hatTrick.stepMetadata?
    hatTrick.stepMetadata[stepId] = metadata

  handleServerData: (data) =>
    if data.metadata?.externalRedirectURL?
      externalRedirectURL = data.metadata.externalRedirectURL
      if externalRedirectURL isnt ""
        location.href = data.metadata.externalRedirectURL
        # TODO: pop out of window if in iframe
        # if (top.location == self.location)
        #   location.href = data.metadata.externalRedirectURL
        # else
        #   window.open(data.metadata.externalRedirectURL)

    if data.metadata?.url? and data.metadata?.method?
      this.setAction(data.metadata.url, data.metadata.method)
    this.saveStepMetadata(data.metadata.currentStep.name, data.metadata.currentStep)
    $.extend(hatTrick, data) # merge new data with hatTrick
    this.updateStepFromMetadata()

  metadataRequestCallback: (data) =>
    stepId = this.currentStepId()
    # set empty step contents if we didn't get any;
    # this makes sure we can tell whether or not we've already requested metadata
    emptyStepContents = { hatTrickStepContents: {} }
    stepKey = camelizeString(stepId)
    emptyStepContents["hatTrickStepContents"][stepKey] = ""
    unless data.data.hatTrickStepContents? and data.data.hatTrickStepContents[stepKey]?
      data.data = $.extend({}, data.data, emptyStepContents)
    this.handleServerData(data)
    this.removeLinkFields() # updateStepFromMetadata sets this to currentStep
    this.setupButtonsForCurrentStep()
    this.updateButtons()
    this.setFormFields(hatTrick.model)
    @form.trigger "step_changed", { currentStep: stepId }

  requestMetadataFromServer: ->
    metadataUrl = document.location.pathname
    lastChar = metadataUrl.charAt(metadataUrl.length - 1)
    metadataUrl += "/" unless lastChar is "/"
    stepId = this.currentStepId()
    metadataUrl += "#{stepId}/" if metadataUrl.search("#{stepId}/$") is -1
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
    this.setHiddenInput "#{this.modelName()}[_dummy]", "1", "", this.currentStep()

  currentStepHasModelFields: ->
    this.currentStep().find("input[name^='#{this.modelName()}[']").length > 0

  updateStepFromMetadata: ->
    currentStepId = this.currentStepId()

    if $("fieldset##{currentStepId}").data("contents") is "server"
      this.updateStepContents()

    if hatTrick.metadata?.currentStep?
      currentStepData = hatTrick.metadata.currentStep
      this.setCurrentStepField()
      this.setButtonMetadataForCurrentStep()
      this.createDummyModelField() unless this.currentStepHasModelFields()
      this.setLinkField(currentStepData.fieldset)

  bindEvents: ->
    @form.bind "step_shown", (event, data) =>
      this.stepShownCallback()

$ ->
  if $("form.wizard").length > 0
    $form = $("form.wizard")
    window.hatTrick ?= {}
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
  if window['console']? and hatTrick.wizard.debug()
    console.log msg
