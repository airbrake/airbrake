class Project
  attr_writer :name, :id, :api_key

  def initialize(attributes = {})
    attributes.keys.each do |key|
      instance_variable_set("@#{key}",attributes[key])
    end
  end

  def to_s
    "#{@name}".rjust(20) + "(#{@id}):".rjust(10) + " #{@api_key}"
  end

  def valid?
    @name && @id && @api_key
  end
end
