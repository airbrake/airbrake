# stolen from ActiveSupport

class Object
  unless method_defined?(:blank?)
    def blank?
      respond_to?(:empty?) ? empty? : !self
    end
  end

  unless method_defined?(:present?)
    def present?
      !blank?
    end
  end

  unless method_defined?(:presence)
    def presence
      self if present?
    end
  end
end

class NilClass
  unless method_defined?(:blank?)
    def blank?
      true
    end
  end
end

class FalseClass
  unless method_defined?(:blank?)
    def blank?
      true
    end
  end
end

class TrueClass
  unless method_defined?(:blank?)
    def blank?
      false
    end
  end
end

class Array
  unless method_defined?(:blank?)
    alias_method :blank?, :empty?
  end
end

class Hash
  unless method_defined?(:blank?)
    alias_method :blank?, :empty?
  end
end

class String
  unless method_defined?(:blank?)
    def blank?
      self !~ /[^[:space:]]/
    end
  end
end

class Numeric
  unless method_defined?(:blank?)
    def blank?
      false
    end
  end
end
