module RailsHelpers
  def rails_version
    environment_file = File.join(RAILS_ROOT, 'config', 'environment.rb')
    @rails_version ||= `grep RAILS_GEM_VERSION #{environment_file}`.match(/[\d.]+/)[0]
  end

  def rails_manages_gems?
    rails_version =~ /^2\.[123]/
  end

  def rails_supports_initializers?
    rails_version =~ /^2\./
  end

  def rails_finds_generators_in_gems?
    rails_version =~ /^2\./
  end

  def environment_path
    File.join(RAILS_ROOT, 'config', 'environment.rb')
  end
end

World(RailsHelpers)
