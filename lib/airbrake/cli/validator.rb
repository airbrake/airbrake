module Validator
  def validates(*attributes)
    attributes.each do |attribute|
      abort "You didn't provide #{attribute.to_s.upcase}"\
        " so no API request was made." unless Runner.options.send(attribute)
    end
  end
end
