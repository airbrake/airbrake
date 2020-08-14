# frozen_string_literal: true

RSpec::Matchers.define :a_notice_with do |access_keys, expected_val|
  match do |notice|
    payload = notice[access_keys.shift]
    break(false) unless payload

    actual_val =
      if payload.respond_to?(:dig)
        payload.dig(*access_keys)
      else
        dig_pre_23(payload, *access_keys)
      end

    if expected_val.is_a?(Regexp)
      actual_val =~ expected_val
    else
      actual_val == expected_val
    end
  end

  # TODO: Use the normal "dig" version once we support Ruby 2.3 and above.
  def dig_pre_23(hash, *keys)
    v = hash[keys.shift]
    while keys.any?
      return unless v.is_a?(Hash)

      v = v[keys.shift]
    end
    v
  end
end
