#= require vendor_js

updateForm = (form, metadata) ->
  $form = $(form)
  $form.attr("action", metadata.url)
  $form.attr("method", metadata.method)

createAjaxEvents = (form, firstStep=true) ->
  $form = $(form)
  remoteAjax = {}
  $steps = $form.find(".step")
  $steps = $steps.filter(":first") if firstStep
  $steps.each (index, element) ->
    console.log "Adding AJAX to step #{index}"
    remoteAjax[$(element).attr("id")] =
      url: $form.attr("action"),
      dataType: "json",
      beforeSubmit: (data) ->
        console.log "Sending these data to the server: #{$.param(data)}"
      success: (data) ->
        console.log "Successful form POST; got #{$.param(data)}"
        updateForm($form, data.ht)
  remoteAjax

$ ->
  $form = $("form.wizard")
  updateForm($form, ht.wizardMetadata)

  $fieldsets = $form.find "fieldset"

  $fieldsets.addClass "step"

  wizard_buttons = '<input type="reset" /><input type="submit" />'
  $fieldsets.find("div.buttons").html wizard_buttons

  $form.formwizard
    formPluginEnabled: true,
    validationEnabled: true,
    focusFirstInput: true,
    historyEnabled: true,
    disableUIStyles: true,
    remoteAjax: createAjaxEvents($form), # adds first Ajax event
    formOptions:
      success: (data) ->
        console.log "Successful form POST"
      beforeSubmit: (data) ->
        console.log "Sending these data to the server: #{$.param(data)}"

  $form.bind "step_shown", (event, data) ->
    if data.previousStep is data.firstStep
      console.log("Adding additional Ajax events")
      # adds additional Ajax events now that we have the update URL
      $form.formwizard("option", remoteAjax: createAjaxEvents($form, false))

