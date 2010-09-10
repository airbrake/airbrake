Spec::Matchers.define :have_content do |xpath, content|
  match do |document|
    @elements = document.search(xpath)

    if @elements.empty?
      false
    else
      element_with_content = document.at("#{xpath}[contains(.,'#{content}')]")

      if element_with_content.nil?
        @found = @elements.collect { |element| element.content }

        false
      else
        true
      end
    end
  end

  failure_message_for_should do |document|
    if @elements.empty?
      "In XML:\n#{document}\nNo element at #{xpath}"
    else
      "In XML:\n#{document}\nGot content #{@found.inspect} at #{xpath} instead of #{content.inspect}"
    end
  end

  failure_message_for_should_not do |document|
    unless @elements.empty?
      "In XML:\n#{document}\nExpcted no content #{content.inspect} at #{xpath}"
    end
  end
end
