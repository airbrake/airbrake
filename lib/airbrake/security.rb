module Airbrake
  module Security

    def self.ca_bundle_path
      if File.exist?(OpenSSL::X509::DEFAULT_CERT_FILE)
        path = OpenSSL::X509::DEFAULT_CERT_FILE
      else
        path = local_cert_path
      end
      return path
    end

    def self.local_cert_path
      File.expand_path(File.join("..", "..", "..", "resources", "ca-bundle.crt"), __FILE__)
    end

  end
end