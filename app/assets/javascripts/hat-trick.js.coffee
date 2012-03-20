#= require vendor_js

$ ->
  $form = $("form.wizard")
  $form.attr("data-model-url", "/foo")

  $fieldsets = $form.find "fieldset"

  $fieldsets.addClass "step"

  wizard_buttons = '<input type="reset" /><input type="submit" />'
  $fieldsets.find("div.buttons").html wizard_buttons

  remoteAjax = {}
  $form.find(".step").each (index, element) ->
    console.log "Adding AJAX to step #{index}"
    remoteAjax[$(element).attr("id")] =
      url: $form.attr("action"),
      dataType: "json",
      beforeSubmit: (data) ->
        console.log "Sending these data to the server: #{$.param(data)}"
      success: (data) ->
        console.log "Successful form POST"
        true

  $form.formwizard
    formPluginEnabled: true,
    validationEnabled: true,
    focusFirstInput: true,
    historyEnabled: true,
    disableUIStyles: true,
    remoteAjax: remoteAjax,
    formOptions:
      success: (data) ->
        console.log "Successful form POST"
      beforeSubmit: (data) ->
        console.log "Sending these data to the server: #{$.param(data)}"

updateModel = (url, callback) ->
  $.getJSON url, callback
