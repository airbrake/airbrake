class Options

  ATTRIBUTES = [:error, :message, :api_key, :host, :port, :auth_token, :name, :account, :rails_env, :scm_revision]

  ATTRIBUTES.each do |attribute|
    attr_reader attribute
  end

  private

  # You should not write to this from outside
  ATTRIBUTES.each do |attribute|
    attr_writer attribute
  end

  public

  # Parses all the options passed and stores them in attributes
  def initialize(array = [])
    opts = Hash[*array]
    self.error         = opts.delete("-e")  || opts.delete("--error")   { RuntimeError }
    self.message       = opts.delete("-m")  || opts.delete("--message") { "I've made a huge mistake" }
    self.api_key       = opts.delete("-k")  || opts.delete("--api-key")    || config_from_file.api_key || ENV["AIRBRAKE_API_KEY"]
    self.host          = opts.delete("-h")  || opts.delete("--host")       || config_from_file.host
    self.port          = opts.delete("-p")  || opts.delete("--port")       || config_from_file.port
    self.auth_token    = opts.delete("-t")  || opts.delete("--auth-token") || ENV["AIRBRAKE_AUTH_TOKEN"]
    self.name          = opts.delete("-n")  || opts.delete("--name")
    self.account       = opts.delete("-a")  || opts.delete("--account")    || ENV["AIRBRAKE_ACCOUNT"]
    self.rails_env     = opts.delete("-E")  || opts.delete("--rails-env")  || ENV["RAILS_ENV"] || "production"
    self.scm_revision  = opts.delete("-r")  || opts.delete("--scm-revision")
    opts
  end

  # Fallback to read from the initializer
  def config_from_file
    begin
      load "config/initializers/airbrake.rb"
    rescue LoadError
    end
    Airbrake.configuration
  end
end
