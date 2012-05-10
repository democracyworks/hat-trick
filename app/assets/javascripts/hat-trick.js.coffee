#= require vendor_js

class HatTrickWizard
  constructor: (formElem, @wizard) ->
    @form = $(formElem)
    fieldsets = @form.find("fieldset")
    fieldsets.addClass("step")
    # prevent submitting the step that happens to be the last fieldset
    this.addDefaultButtons()
    this.addFakeLastStep()
    this.enableFormwizard()
    this.setCurrentStepField()
    this.bindEvents()

  linkClass: "_ht_link"

  buttons: {}

  addDefaultButtons: ($scope = @form.find("fieldset")) ->
    wizard_buttons = '<input type="reset" /><input type="submit" />'
    $scope.find("div.buttons").prepend wizard_buttons

  findStep: (stepId) ->
    @form.find("fieldset##{stepId}")

  createMethodField: (method) ->
    """<input type="hidden" name="_method" value="#{method}" />"""

  setAction: (url, method) ->
    methodLower = method.toLowerCase()
    # console.log "Setting form action to #{methodLower} #{url}"
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
      url: @form.attr("action"),
      dataType: "json",
      beforeSubmit: (data) =>
        # console.log "Sending these data to the server: #{JSON.stringify(data)}"
        true
      success: (response) =>
        # console.log "Successful form POST; got #{JSON.stringify(response)}"
        if response.metadata?
          this.setAction(response.metadata.url, response.metadata.method)
        $.extend(window.hatTrick, response) # merge new data with hatTrick
      error: (event) =>
        console.log "Error response: #{event.responseText}"
        try
          appErrors = eval "(#{event.responseText})"
        catch err
          # TODO: Make this notify us when an error occurs.
          appErrors = model: { unknown: ["A weird error has occurred."] }
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
    console.log "Setting up goto #{stepId}"
    this.showStep(stepId)
    @form.formwizard("next")

  repeatStep: (step) ->
    $sourceStep = this.findStep(step.repeatOf.fieldset)
    # console.log "Cloning repeated step #{step.repeatOf.fieldset}"
    $clonedStep = $sourceStep.clone(true, true)
    $clonedStep.css("display", "none")
    $clonedStep.attr("id", step.name)
    $sourceStep.after($clonedStep)
    this.updateSteps()
    @form.formwizard("show", step.name)

  showStep: (stepId) ->
    inputId = "_ht_link_to_#{stepId}"
    this.setHiddenInput "_ht_step_link", stepId, inputId, @linkClass, this.currentStep()

  formwizardEnabled: ->
    @form.formwizard?

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
      formOptions:
        success: (data) =>
          # console.log "Successful form POST"
          true
        beforeSubmit: (data) =>
          console.log "Sending these data to the server: #{JSON.stringify(data)}"

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
    # console.log "Current form step: #{stepId}"

  clearNextStepField: ->
    this.clearHTMeta("next_step")

  fieldRegex: /^([^\[]+)\[([^\]]+)\]$/

  setFieldValues: (model, selector, callback) ->
    $currentStep = this.currentStep()
    $currentStep.find(selector).each (index, element) =>
      $element = $(element)
      elementName = $element.attr("name")
      if elementName? and elementName.search(@fieldRegex) isnt -1
        [_, modelName, fieldName] = elementName.match(@fieldRegex)
        if model[fieldName]?
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
    # console.log "Setting form fields based on: #{JSON.stringify(model)}"
    this.fillTextFields(model)
    this.setSelectFields(model)
    this.setCheckboxes(model)
    this.setRadioButtons(model)

  createButton: (name, label) ->
    """<input type="button" name="#{name}" value="#{label}" />"""

  setButton: (name, label) ->
    $buttonsDiv = this.currentStep().find("div.buttons")
    switch name
      when "next"
        # console.log "Setting submit button val to #{label}"
        $buttonsDiv.find('input:submit').val(label)
      when "back"
        # console.log "Setting reset button val to #{label}"
        $buttonsDiv.find('input:reset').val(label)
      else
        buttonSelector = """input:button[name="#{name}"][value="#{label}"]"""
        $existingButtons = $buttonsDiv.find(buttonSelector)
        if $existingButtons.length == 0
          # console.log "Adding new #{name}:#{label} button"
          $newButton = $(this.createButton(name, label)).appendTo($buttonsDiv)
          $newButton.click (event) =>
            event.preventDefault()
            this.goToStepId(name)

  setContents: (stepPartials) ->
    for stepName, partial of stepPartials
      do (stepName, partial) =>
        stepId = underscoreString stepName
        $partial = $(partial)
        fieldsetContents = $partial.find('fieldset').html()
        $step = $("fieldset##{stepId}")
        $step.html fieldsetContents
        this.addDefaultButtons($step)
        this.updateSteps()

  bindEvents: ->
    @form.bind "step_shown", (event, data) =>
      this.setCurrentStepField()
      this.clearNextStepField()
      this.setFormFields(hatTrick.model)

      buttons = this.buttons[this.currentStepId()]
      if buttons?
        this.setButton(name, label) for own name, label of buttons

    @form.bind "after_remote_ajax", (event, data) =>
      if hatTrick.data.hatTrickStepContents?
        this.setContents(hatTrick.data.hatTrickStepContents)

      if hatTrick.metadata?.currentStep.buttons?
        stepId = hatTrick.metadata.currentStep.fieldset
        this.buttons[stepId] = hatTrick.metadata.currentStep.buttons

      if hatTrick.metadata?.currentStep?.repeatOf?
        this.repeatStep(hatTrick.metadata.currentStep)
      else if hatTrick.metadata?.currentStep?
        this.showStep(hatTrick.metadata.currentStep.fieldset)

$ ->
  $form = $("form.wizard")
  window.hatTrick = {} unless window.hatTrick?
  unless window.hatTrick.wizard?
    # console.log "Creating new HatTrickWizard instance"
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
