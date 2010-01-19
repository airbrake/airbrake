Before do
  @terminal = Terminal.new
end

class Terminal
  attr_reader :output, :status

  def initialize
    @cwd = FileUtils.pwd
    @output = ""
    @status = 0
    @logger = Logger.new(File.join(TEMP_DIR, 'terminal.log'))
  end

  def cd(directory)
    @cwd = directory
  end

  def run(command)
    output << "#{command}\n"
    FileUtils.cd(@cwd) do
      logger.debug(command)
      result = `#{environment_settings} #{command} 2>&1`
      logger.debug(result)
      output << result
    end
    @status = $?
  end

  def echo(string)
    logger.debug(string)
  end

  def build_and_install_gem(gemspec)
    pkg_dir = File.join(TEMP_DIR, 'pkg')
    FileUtils.mkdir_p(pkg_dir)
    output = `gem build #{gemspec} 2>&1`
    gem_file = Dir.glob("*.gem").first
    unless gem_file
      raise "Gem didn't build:\n#{output}"
    end
    target = File.join(pkg_dir, gem_file)
    FileUtils.mv(gem_file, target)
    install_gem_to(BUILT_GEM_ROOT, target)
  end

  def install_gem(gem)
    install_gem_to(LOCAL_GEM_ROOT, gem)
  end

  def uninstall_gem(gem)
    `gem uninstall -i #{BUILT_GEM_ROOT} #{gem}`
  end

  private

  def install_gem_to(root, gem)
    `gem install -i #{root} --no-ri --no-rdoc #{gem}`
  end

  def environment_settings
    "GEM_HOME=#{LOCAL_GEM_ROOT} GEM_PATH=#{LOCAL_GEM_ROOT}:#{BUILT_GEM_ROOT}"
  end

  attr_reader :logger
end
