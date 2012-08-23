/*
 * jQuery wizard plug-in 3.0.5
 *
 *
 * Copyright (c) 2011 Jan Sundman (jan.sundman[at]aland.net)
 *
 * http://www.thecodemine.org
 *
 * Licensed under the MIT license:
 *   http://www.opensource.org/licenses/mit-license.php
 *
 */


(function($){
  $.widget("ui.formwizard", {

    _init: function() {

      var wizard = this;
      var formOptionsSuccess = this.options.formOptions.success;
      var formOptionsComplete = this.options.formOptions.complete;
      var formOptionsBeforeSend = this.options.formOptions.beforeSend;
      var formOptionsBeforeSubmit = this.options.formOptions.beforeSubmit;
      var formOptionsBeforeSerialize = this.options.formOptions.beforeSerialize;
      var $firstStep;
      var stateData = {};

      this.options.formOptions = $.extend(this.options.formOptions, {
        success  : function(responseText, textStatus, xhr) {
          if (formOptionsSuccess) {
            formOptionsSuccess(responseText, textStatus, xhr);
          }
          if(wizard.options.formOptions && wizard.options.formOptions.resetForm || !wizard.options.formOptions){
            wizard._reset();
          }
        },
        complete : function(xhr, textStatus){
          if(formOptionsComplete){
            formOptionsComplete(xhr, textStatus);
          }
          wizard._enableNavigation();
        },
        beforeSubmit : function(arr, theForm, options) {
          if(formOptionsBeforeSubmit){
            var shouldSubmit = formOptionsBeforeSubmit(arr, theForm, options);
            if(!shouldSubmit)
              wizard._enableNavigation();
            return shouldSubmit;
          }
        },
        beforeSend : function(xhr) {
          if(formOptionsBeforeSend){
            var shouldSubmit = formOptionsBeforeSend(xhr);
            if(!shouldSubmit)
              wizard._enableNavigation();
            return shouldSubmit;
          }
        },
        beforeSerialize: function(form, options) {
          if(formOptionsBeforeSerialize){
            var shouldSubmit = formOptionsBeforeSerialize(form, options);
            if(!shouldSubmit)
              wizard._enableNavigation();
            return shouldSubmit;
          }
        }
      });

      this.steps = this.element.find(".step").hide();

      this.firstStep = this.options.firstStep || this.steps.eq(0).attr("id");

      $firstStep = this._stepElement(this.firstStep);
      stateData["step"] = this.firstStep;
      History.replaceState(stateData, $firstStep.data("page-title"), location.pathname);

      this.isLastStep = false;
      this.previousStep = undefined;
      this.currentStep = this.firstStep;

      this._updateButtons();

      if (this.options.validationEnabled && jQuery().validate === undefined) {
        this.options.validationEnabled = false;
        if ( (window['console'] !== undefined) ) {
          console.log("%s", "validationEnabled option set, but the validation plugin is not included");
        }
      } else if(this.options.validationEnabled) {
        this.element.validate(this.options.validationOptions);
      }
      if (this.options.formPluginEnabled && jQuery().ajaxSubmit === undefined) {
        this.options.formPluginEnabled = false;
        if ( (window['console'] !== undefined) ) {
          console.log("%s", "formPluginEnabled option set but the form plugin is not included");
        }
      }

      if (this.options.disableInputFields === true) {
        $(this.steps).find(":input:not('.wizard-ignore')").attr("disabled","disabled");
      }

      History.Adapter.bind(window, 'statechange', function() {
        var state;
        var step;
        state = History.getState();
        step = state.data.step;
        if (step !== wizard.currentStep) {
          if (wizard.options.validationEnabled && step === wizard._navigate(wizard.currentStep)) {
            if (!wizard.element.valid()) {
              wizard._show(wizard.currentStep);
              wizard.element.validate().focusInvalid();

              return false;
            }
          }
          if (step !== wizard.currentStep) {
            wizard._show(step);
          }
        }
      });

      this.element.addClass("ui-formwizard");
      this.element.find(":input").addClass("ui-wizard-content");
      this.steps.addClass("ui-formwizard-content");
      this.backButton.addClass("ui-formwizard-button ui-wizard-content");
      this.nextButton.addClass("ui-formwizard-button ui-wizard-content");

      if(!this.options.disableUIStyles){
        this.element.addClass("ui-helper-reset ui-widget ui-widget-content ui-helper-reset ui-corner-all");
        this.element.find(":input").addClass("ui-helper-reset ui-state-default");
        this.steps.addClass("ui-helper-reset ui-corner-all");
        this.backButton.addClass("ui-helper-reset ui-state-default");
        this.nextButton.addClass("ui-helper-reset ui-state-default");
      }
      this._show(undefined);
      return $(this);
    },

    _stepElement : function(stepId) {
      return $(this.steps.filter("#" + stepId)[0]);
    },

    _updateButtons : function() {
      var wizard = this;

      this.nextButton = this.element.find(this.options.next);
      this.nextButton.each(function() {
        var events = $(this).data("events");
        if (typeof events === "undefined" ||
            typeof events['click'] === "undefined" ||
            events['click'].length === 0) {
          $(this).click(function() {
            console.log("Next clicked");
            return wizard._next(this);
          });
        }
      });

      this.backButton  = this.element.find(this.options.back);
      this.backButton.each(function() {
        var events = $(this).data('events');
        if (typeof events === "undefined" ||
            typeof events['click'] === "undefined" ||
            events['click'].length === 0) {
          $(this).click(function() {
            console.log("Back clicked");
            var backClickCallbackData = {
              "currentStep": wizard.currentStep,
              "button": $(this).attr("id")
            };
            $(wizard.element).trigger('back_click', backClickCallbackData);
            wizard._back();
            return false;
          });
        }
      });
    },

    _next : function(button) {
      var nextClickCallbackData = {
        "currentStep": this.currentStep,
        "button": $(button).attr("id")
      };
      $(this.element).trigger('next_click', nextClickCallbackData);

      if (this.options.validationEnabled) {
        if (!this.element.valid()) {
          this.element.validate().focusInvalid();
          return false;
        }
      }

      if (this.options.remoteAjax !== undefined) {
        var options = this.options.remoteAjax[this.currentStep];
        var wizard = this;
        if (options !== undefined) {
          var success = options.success;
          var beforeSend = options.beforeSend;
          var complete = options.complete;

          options = $.extend({}, options, {
            beforeSerialize : function(form, options) {
              var $button;
              var buttonName;
              var buttonValue;
              var buttonData = {};

              // serialize the button that was clicked into the ajax submission
              $button = $(button);
              buttonName = $button.attr("name");
              buttonValue = $button.val();
              if (buttonName !== undefined && buttonName !== "" && buttonValue !== undefined && buttonValue !== "") {
                buttonData[buttonName] = buttonValue;
                options.data = $.extend({}, options.data, buttonData);
              }
              return true;
            },

            beforeSend : function(xhr){
              wizard._disableNavigation();
              if(beforeSend !== undefined)
                beforeSend(xhr);
              $(wizard.element).trigger('before_remote_ajax', {
                "xhr": xhr,
                "currentStep" : wizard.currentStep
              });
            },
            complete : function(xhr, statusText){
              if(complete !== undefined)
                complete(xhr, statusText);
              $(wizard.element).trigger('after_remote_ajax', {
                "xhr": xhr,
                "statusText": statusText,
                "currentStep" : wizard.currentStep
              });

              if (statusText === "success") {
                wizard._continueToNextStep();
              }

              wizard._enableNavigation();
            }
          });
          this.element.ajaxSubmit(options);
          return false;
        }
      }

      return this._continueToNextStep();
    },

    _back : function() {
      History.back();
      return false;
    },

    _continueToNextStep : function(){
      var step = this._navigate(this.currentStep);
      if (step == this.currentStep) {
        return false;
      }
      this._updateHistory(step);
      return false;
    },

    _pageTitleForStep : function(step) {
      var $step = this._stepElement(step);
      var title = $step.data("page-title");
      return title;
    },

    _updateHistory : function(step) {
      var stateData = {};
      var newUrlPath = this._urlPathForStep(step);
      var title = this._pageTitleForStep(step);

      stateData["step"] = step;
      History.pushState(stateData, title, newUrlPath);
    },

    _urlPathForStep : function(step) {
      var currentState = History.getState();
      var currentStep = this.currentStep;
      var urlPathComponents;
      var newUrlPathComponents = [];
      var newUrl;
      var i;
      var lastIndex;

      urlPathComponents = currentState.url.split("/").filter(function(c) {
        return (c !== "");
      });
      urlPathComponents.shift(); // drop first element; the "http(s):"
      urlPathComponents.shift(); // next element is host:port section; drop it
      lastIndex = urlPathComponents.length - 1;

      for (i=0; i<lastIndex; i++) {
        newUrlPathComponents.push(urlPathComponents[i]);
      }

      // remove any query params from the end of the URL
      lastPathComponent = urlPathComponents[lastIndex].split("?")[0];

      if (lastPathComponent !== currentStep) {
        newUrlPathComponents.push(lastPathComponent);
      }

      newUrlPathComponents.push(step);
      newUrl = "/" + newUrlPathComponents.join("/");

      return newUrl;
    },

    _redirect : function(step) {
      var stepUrlPath = this._urlPathForStep(step);
      location.pathname = stepUrlPath;
    },

    _disableNavigation : function() {
      this.nextButton.attr("disabled","disabled");
      this.backButton.attr("disabled","disabled");
      if(!this.options.disableUIStyles){
        this.nextButton.removeClass("ui-state-active").addClass("ui-state-disabled");
        this.backButton.removeClass("ui-state-active").addClass("ui-state-disabled");
      }
    },

    _enableNavigation : function(){
      if($.trim(this.currentStep) !== this.steps.eq(0).attr("id")){
        this.backButton.removeAttr("disabled");
        if(!this.options.disableUIStyles){
          this.backButton.removeClass("ui-state-disabled").addClass("ui-state-active");
        }
      }

      this.nextButton.removeAttr("disabled");
      if(!this.options.disableUIStyles){
        this.nextButton.removeClass("ui-state-disabled").addClass("ui-state-active");
      }
    },

    _animate : function(oldStep, newStep, stepShownCallback){
      this._disableNavigation();
      var old = this.steps.filter("#" + oldStep);
      var current = this.steps.filter("#" + newStep);
      old.find(":input").not(".wizard-ignore").attr("disabled","disabled");
      current.find(":input").not(".wizard-ignore").removeAttr("disabled");
      var wizard = this;
      old.animate(wizard.options.outAnimation, wizard.options.outDuration, wizard.options.easing, function(){
        current.animate(wizard.options.inAnimation, wizard.options.inDuration, wizard.options.easing, function(){
          if (wizard.options.focusFirstInput) {
            current.filter("fieldset:not(.no-focus)").find(":input:not(input[type=hidden]):first").focus();
          }
          wizard._enableNavigation();

          stepShownCallback.apply(wizard);
        });
        return;
      });
    },

    _checkIflastStep : function(step){
      this.isLastStep = false;
      if($("#" + step).hasClass(this.options.submitStepClass) || this.steps.filter(":last").attr("id") == step){
        this.isLastStep = true;
      }
    },

    _getLink : function(step) {
      var link;
      var links = this.steps.filter("#" + step).find(this.options.linkClass);

      if (links !== undefined) {
        if (links.filter(":radio,:checkbox").size() > 0) {
          link = links.filter(this.options.linkClass + ":checked").val();
        } else {
          link = $(links).val();
        }
      }
      return link;
    },

    _navigate : function(step) {
      var link = this._getLink(step);
      if (link !== undefined) {
        if ((link !== "" && link !== null && link !== undefined) && this.steps.filter("#" + link).attr("id") !== undefined) {
          return link;
        }
        return this.currentStep;
      } else if (link === undefined && !this.isLastStep) {
        var step1 =  this.steps.filter("#" + step).next().attr("id");
        return step1;
      }
    },

    _stepFromPath : function() {
      var path = window.location.pathname;
      var pathComponents = path.split('/');
      for (var i = pathComponents.length; i >= 0; i--) {
        if (pathComponents[i] !== "") {
          return pathComponents[i];
        }
      }
    },

    _show : function(step) {
      var fragment;
      if (step === undefined || step === "") {
        step = this._stepFromPath() || this.firstStep;
      }

      if (this.currentStep !== step || step === this.firstStep) {
        this.previousStep = this.currentStep;
        this._checkIflastStep(step);
        this.currentStep = step;
        var stepShownCallback = function() {
          $(this.element).trigger('step_shown', this._state());
        };
        this._animate(this.previousStep, step, stepShownCallback);
      }

    },

     _reset : function(){
      this.element.resetForm();
      $("label,:input,textarea",this).removeClass("error");
      this.previousStep = undefined;
      this.isLastStep = false;
      this._updateHistory(this.firstStep);
    },

    _state : function(state) {
      var currentState = { "settings" : this.options,
        "isLastStep" : this.isLastStep,
        "isFirstStep" : this.currentStep === this.firstStep,
        "previousStep" : this.previousStep,
        "currentStep" : this.currentStep,
        "backButton" : this.backButton,
        "nextButton" : this.nextButton,
        "steps" : this.steps,
        "firstStep" : this.firstStep
      };

      if (state !== undefined) {
        return currentState[state];
      }

      return currentState;
    },

    /*Methods*/

    show : function(step) {
      this._updateHistory(step);
    },

    redirect : function(step) {
      this._redirect(step);
    },

    state : function(state){
      return this._state(state);
    },

    reset : function(){
      this._reset();
    },

    next : function(){
      this._next();
    },

    back : function(){
      this._back();
    },

    destroy: function() {
      this.element.find("*").removeAttr("disabled").show();
      this.nextButton.unbind("click").val(this.nextButtonInitinalValue).removeClass("ui-state-disabled").addClass("ui-state-active");
      this.backButton.unbind("click").val(this.backButtonInitinalValue).removeClass("ui-state-disabled").addClass("ui-state-active");
      this.backButtonInitinalValue = undefined;
      this.nextButtonInitinalValue = undefined;
      this.previousStep = undefined;
      this.currentStep = undefined;
      this.isLastStep = undefined;
      this.options = undefined;
      this.nextButton = undefined;
      this.backButton = undefined;
      this.formwizard = undefined;
      this.element = undefined;
      this.steps = undefined;
      this.firstStep = undefined;
    },

    update_steps : function(){
      this.steps = this.element.find(".step").addClass("ui-formwizard-content");
      this.steps.not("#" + this.currentStep).hide().find(":input").addClass("ui-wizard-content").attr("disabled","disabled");
      this._updateButtons();
      this._checkIflastStep(this.currentStep);
      this._enableNavigation();
      if(!this.options.disableUIStyles){
        this.steps.addClass("ui-helper-reset ui-corner-all");
        this.steps.find(":input").addClass("ui-helper-reset ui-state-default");
      }
    },

    update_buttons : function() {
      this._updateButtons();
    },

    options: {
      validationEnabled : false,
      validationOptions : undefined,
      formPluginEnabled : false,
      linkClass  : ".link",
      submitStepClass : "submit_step",
      back : "input:reset",
      next : "input:submit",
      textSubmit : 'Submit',
      textNext : 'Next',
      textBack : 'Back',
      remoteAjax : undefined,
      inAnimation : {opacity: 'show'},
      outAnimation: {opacity: 'hide'},
      inDuration : 400,
      outDuration: 400,
      easing: 'swing',
      focusFirstInput : false,
      disableInputFields : true,
      formOptions : { reset: true, success: function(data) { if( (window['console'] !== undefined) ){console.log("%s", "form submit successful");}},
      disableUIStyles : false
    }
   }
 });
})(jQuery);
