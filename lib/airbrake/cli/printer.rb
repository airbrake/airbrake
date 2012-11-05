module Printer
  def self.print(collection)
    collection.each do |element|
      puts element
    end
  end

  def self.print_usage
    puts <<-USAGE
Usage: airbrake [COMMAND] [OPTION]...
Commands:
  raise                          # Raise an exception specified by ERROR and MESSAGE.
  list                           # List all the projects for given AUTH_TOKEN and ACCOUNT.
  create                         # Create a project with the given NAME.
  deploy                         # Send a new deployment notification to a project that matches the API_KEY.

Options:
  -e, [--error=ERROR]            # Error class to raise. Default:  RuntimeError
  -m, [--message=MESSAGE]        # Error message. Default: "I've made a huge mistake"
  -k, [--api-key=API_KEY]        # Api key of your Airbrake application.
  -h, [--host=HOST]              # URL of the Airbrake API server. Default: api.airbrake.io
  -p, [--port=PORT]              # Port of the Airbrake API server. Default: 80
  -t, [--auth-token=AUTH_TOKEN]  # The auth token used for API requests.
  -a, [--account=ACCOUNT]        # The account used for API requests.
  -n, [--name=NAME]              # The name of the project you're trying to create.
  -E, [--rails-env=NAME]         # The name of the environment you're deploying to. Default: production
  -h, [--help]                   # Show this usage
   USAGE
  end
end
