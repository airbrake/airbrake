module Airbrake
  class Def
    def self.rails?
      defined?(Rails) && defined?(Rails.version)
    end
  end
end