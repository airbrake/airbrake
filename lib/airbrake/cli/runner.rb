require File.expand_path( "../project_factory", __FILE__)
require File.expand_path( "../options", __FILE__)
require File.expand_path( "../validator", __FILE__)
require File.expand_path( "../printer", __FILE__)
require File.expand_path( "../client", __FILE__)

module Runner
  extend Validator

  extend self

  attr_accessor :options

  def run!(command, cli_options = {})

    self.options = Options.new(cli_options)

    case command
    when 'raise'
      validates :api_key
      Airbrake.configure do |c|
        c.api_key = options.api_key
        c.host    = options.host if options.host
        c.port    = options.port if options.port
        c.secure  = options.port.to_i == 443
      end
      exception_id = Airbrake.notify(:error_class   => options.error,
                                     :error_message => "#{options.error}: #{options.message}",
                                     :cgi_data      => ENV)
      abort "Error sending exception to Airbrake server. Try again later." unless exception_id
      puts "Exception sent successfully: http://airbrake.io/locate/#{exception_id}"

    when "list"
      validates :auth_token, :account
      Client.print_projects

    when "create"
      validates :auth_token, :account
      Client.create_project

    when "deploy"
      validates :api_key
      Client.create_deploy

    else
      Printer.print_usage
    end
  end
end
