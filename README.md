# Hat Trick
> Combines jQuery FormWizard, validation_group, and gon for the perfect triple-play of Rails wizarding.

## Install
    gem install hat-trick

### Rails 3.2
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

In your view:

    <%= wizard_form_for @model do |f| %>
      <fieldset id="first_step">...</fieldset>
      <fieldset id="second_step">...</fieldset>
      <fieldset id="third_step">...</fieldset>
    <% end %>
    
## Controlling the wizard flow
Sometimes you need to specify different paths through a wizard. The way you do that with hat-trick is in the wizard DSL in the controller. Here are some examples:

Jumping to a step based on logged in status:

    wizard do
      step :first_step do
        # after_this_step defines a callback to run after the current step is completed by the user
        after_this_step do
          # code in this block will be exec'd in the context of your controller
          if user_signed_in?
            next_step :third_step
          end
        end
      end
      
      step :second_step # wizard will go here after :first_step if user is not signed in
      
      step :third_step # wizard will go here after :first_step if user is signed in
      
Repeating a previous step (for example, to show address sanitization results to the user):
  
     wizard do
       step :enter_address
        
       step :confirm_santized_address do
         repeat_step :enter_address
       end
       
Skipping a step under certain conditions:

    wizard do
      step :first_step
      step :second_step do
        # before_this_step defines a callback to run before the user sees this step
        before_this_step do
          # code in this block will be exec'd in the context of your controller
          skip_this_step unless foo.present?
        end
      end
    end