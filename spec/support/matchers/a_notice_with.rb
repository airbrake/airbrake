# frozen_string_literal: true

RSpec::Matchers.define :a_notice_with do |access_keys, expected_val|
  match do |notice|
    payload = notice[access_keys.shift]
    break(false) unless payload

    actual_val = payload.dig(*access_keys)

    if expected_val.is_a?(Regexp)
      actual_val =~ expected_val
    else
      actual_val == expected_val
    end
  end
end
