# stolen from ActiveSupport

class Object
  # Don't override already defined or aliased methods
  #
  def safe_def(name,&blk)
    unless method_defined?(name.to_sym)
      self.send(:define_method,name, &blk)
    end
  end

  def safe_alias(new_method, orig_method)
    unless method_defined?(new_method.to_sym)
      alias_method(new_method, orig_method)
    end
  end

  safe_def(:blank?) do
    respond_to?(:empty?) ? empty? : !self
  end

  safe_def(:present?) do
    !blank?
  end

  safe_def(:presence) do
    self if present?
  end
end

class NilClass
  safe_def(:blank?) do
    true
  end
end

class FalseClass
  safe_def(:blank?) do
    true
  end
end

class TrueClass
  safe_def(:blank?) do
    false
  end
end

class Array
  safe_alias(:blank?, :empty?)
end

class Hash
  safe_alias(:blank?, :empty?)
end

class String
  safe_def(:blank?) do
    self !~ /[^[:space:]]/
  end
end

class Numeric
  safe_def(:blank?) do
    false
  end
end
