require File.dirname(__FILE__) + '/helper'

require 'capistrano/configuration'
require 'airbrake/capistrano'

class CapistranoTest < Test::Unit::TestCase
  def setup
    super
    reset_config
    
    @configuration = Capistrano::Configuration.new
    Airbrake::Capistrano.load_into(@configuration)
    @configuration.dry_run = true
  end
  
  should "define airbrake:deploy task" do
    assert_not_nil @configuration.find_task('airbrake:deploy')
  end
  
  should "log when calling airbrake:deploy task" do
    @configuration.set(:current_revision, '084505b1c0e0bcf1526e673bb6ac99fbcb18aecc')
    @configuration.set(:repository, 'repository')
    @configuration.set(:current_release, '/home/deploy/rails_app/hoptoad')
    io = StringIO.new
    logger = Capistrano::Logger.new(:output => io)
    logger.level = Capistrano::Logger::MAX_LEVEL
    
    @configuration.logger = logger
    @configuration.find_and_execute_task('airbrake:deploy')
    
    assert io.string.include?('** Notifying Airbrake of Deploy')
    assert io.string.include?('** Airbrake Notification Complete')
  end
end
