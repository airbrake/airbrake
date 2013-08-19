module Airbrake
  class Response
    def self.pretty_format(xml_body)
      new(xml_body)
    rescue
      xml_body
    end

    def to_s
      output = "\n"
      output = "UUID: #{@id}"
      output << "\n"
      output << "URL:  #{@url}"
      output
    end

    private

    def initialize(xml_body)
      @xml_body = xml_body
      @url      = parse_tag("url")
      @id       = parse_tag("id")
    end

    def parse_tag(name)
      @xml_body.match(%r{<#{name}[^>]*>(.*?)</#{name}>})[1]
    end
  end
end
