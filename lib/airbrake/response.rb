module Airbrake
  class Response
    def self.pretty_format(xml_body)
      new(xml_body)
    rescue
      xml_body
    end

    def to_s
      output = "\n"
      output = "UUID: #{id}"
      output << "\n"
      output << "URL:  #{url}"
      output
    end

    private

    attr_accessor :xml_body, :url, :id

    def initialize(xml_body)
      self.xml_body = xml_body
      self.url      = parse_tag("url")
      self.id       = parse_tag("id")
    end

    def parse_tag(name)
      xml_body.match(%r{<#{name}[^>]*>(.*?)</#{name}>})[1]
    end
  end
end
