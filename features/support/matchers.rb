module Matchers
  def have_content(xpath, content)
    simple_matcher "have #{content.inspect} at #{xpath}" do |doc, matcher|
      elements = doc.search(xpath)
      if elements.empty?
        matcher.failure_message = "In XML:\n#{doc}\nNo element at #{xpath}"
        false
      else
        element_with_content = doc.at("#{xpath}[contains(.,'#{content}')]")
        if element_with_content.nil?
          found = elements.collect { |element| element.content }
          matcher.failure_message =
            "In XML:\n#{doc}\n" +
            "Got content #{found.inspect} at #{xpath} instead of #{content.inspect}"
          false
        else
          true
        end
      end
    end
  end
end

World(Matchers)
