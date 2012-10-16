# Hat Trick

> Multi-step "wizard" forms in Rails using jQuery. Keeps your controller CRUD
> methods clean with a wizard DSL.

## Install
    gem install hat-trick

### Rails 3.1+
(older versions not supported)

Put this in your Gemfile:

    gem 'hat-trick'

## Setup
In your controller:

    wizard do
      step :first_step
      step :second_step
      step :third_step
    end

**Make sure your controller's CRUD methods know how to return JSON responses
containing the model instance you're building in the wizard.**

In your view:

    <%= wizard_form_for @model do |f| %>
      <fieldset id="first_step">...</fieldset>
      <fieldset id="second_step">...</fieldset>
      <fieldset id="third_step">...</fieldset>
    <% end %>

The id's of the fieldsets in your form should match the step names you define in your controller.

Each fieldset will be displayed as a step with Next and Back buttons.

## Controlling the wizard flow
Sometimes you need to specify different paths through a wizard based on certain conditions. The way you do that with hat-trick is in the wizard DSL in the controller. Here are some examples:

Jumping to a step based on logged in status:

    wizard do
      step :first_step do
        # after defines a callback to run after the current step is completed by the user
        after do
          # code in this block will be exec'd in the context of your controller
          if current_user?
            next_step :third_step
          end
        end
      end

      step :second_step # wizard will go here after :first_step if user is not signed in

      step :third_step # wizard will go here after :first_step if user is signed in

Skipping a step under certain conditions:

    wizard do
      step :first_step
      step :second_step do
        # before defines a callback to run before the user sees this step
        before do
          # code in this block will be exec'd in the context of your controller
          skip_this_step unless model.foo.present?
        end
      end
    end

Using the model instance in before and after callbacks:

    wizard do
      step :first_step do
        before do |model_instance|
          if model_instance.attr.present?
            next_step :third_step
          end
        end
      end
    end

Customizing the button labels:

    wizard do
      button_label :next, "Onward!"
      button_label :back, "Engines reverse full"
    end

Adding a custom button to a step:

    wizard do
      step :first_step do
        button_to :next, name: "model[button_name]", label: "Foobar"
      end
    end
