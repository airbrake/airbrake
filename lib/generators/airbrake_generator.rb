# frozen_string_literal: true

# Creates the Airbrake initializer file for Rails apps.
#
# @example Invokation from terminal
#   rails generate airbrake [NAME]
#
class AirbrakeGenerator < Rails::Generators::Base
  # Adds current directory to source paths, so we can find the template file.
  source_root File.expand_path(__dir__)

  # Makes the NAME option optional, which allows to subclass from Base, so we
  # can pass arguments to the ERB template.
  #
  # @see https://asciicasts.com/episodes/218-making-generators-in-rails-3.html
  argument :name, type: :string, default: 'application'

  desc 'Configures the Airbrake notifier'
  def generate_layout
    template 'airbrake_initializer.rb.erb', 'config/initializers/airbrake.rb'
  end
end
