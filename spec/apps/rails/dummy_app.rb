class DummyApp < Rails::Application
  # Rails requires these two keys.
  config.session_store :cookie_store, key: 'jiez4Mielu1AiHugog3shiiPhe3lai3faer'
  config.secret_token = 'ni6aeph6aeriBiphesh8omahv6cohpue5Quah5ceiMohtuvei8'

  if Gem::Version.new(Rails.version) > Gem::Version.new('3.2.0')
    config.secret_key_base = '62773890cad9d9d584b57320f8612f8f7378a90aadcabc6ee'
  end

  # Configure a logger, without it the tests can't run.
  vsn = Rails.version.split('').values_at(0, 2).join('')
  log_path = File.join(File.dirname(__FILE__), 'logs', "#{vsn}.log")
  config.logger = Logger.new(log_path)
  Rails.logger = config.logger

  config.active_support.deprecation = :stderr

  config.middleware.use Warden::Manager

  # In Rails 4.2.x Active Record suppresses errors raised within
  # 'after_rollback' & 'after_commit' callbacks and only print them to the
  # logs. In the next version, these errors will no longer be suppressed.
  # Instead, the errors will propagate normally just like in other Active Record
  # callbacks.
  config.active_record.raise_in_transactional_callbacks = true if vsn == '42'

  # Silences the warning, which says 'config.eager_load is set to nil'.
  config.eager_load = false

  routes.append do
    get '/' => 'dummy#index'
    get '/crash' => 'dummy#crash'
    get '/notify_airbrake_helper' => 'dummy#notify_airbrake_helper'
    get '/notify_airbrake_sync_helper' => 'dummy#notify_airbrake_sync_helper'
    get '/active_record_after_commit' => 'dummy#active_record_after_commit'
    get '/active_record_after_rollback' => 'dummy#active_record_after_rollback'
    get '/active_job' => 'dummy#active_job'
    get '/resque' => 'dummy#resque'
    get '/delayed_job' => 'dummy#delayed_job'
  end
end

class Book < ActiveRecord::Base
  after_commit :raise_error_after_commit
  after_rollback :raise_error_after_rollback

  def raise_error_after_commit
    raise AirbrakeTestError, 'after_commit'
  end

  def raise_error_after_rollback
    raise AirbrakeTestError, 'after_rollback'
  end
end

# ActiveJob.
if Gem::Version.new(Rails.version) >= Gem::Version.new('4.2')
  class BingoJob < ActiveJob::Base
    queue_as :bingo

    class BingoWrapper
      def initialize(bingo)
        @bingo = bingo
      end
    end

    def perform(*_args)
      @wrapper = BingoWrapper.new(self)
      raise AirbrakeTestError, 'active_job error'
    end
  end
end

# Resque.
class BingoWorker
  @queue = :bingo_workers_queue

  def self.perform(_bango, _bongo)
    raise AirbrakeTestError, 'resque error'
  end
end

# DelayedJob.
BangoJob = Struct.new(:bingo, :bongo) do
  def perform
    raise AirbrakeTestError, 'delayed_job error'
  end
end

class DummyController < ActionController::Base
  layout 'application'

  self.view_paths = [
    ActionView::FixtureResolver.new(
      'layouts/application.html.erb' => '<%= yield %>',
      'dummy/index.html.erb' => 'Hello from index',
      'dummy/notify_airbrake_helper.html.erb' => 'notify_airbrake_helper',
      'dummy/notify_airbrake_sync_helper.html.erb' => 'notify_airbrake_helper_sync',
      'dummy/active_record_after_commit.html.erb' => 'active_record_after_commit',
      'dummy/active_record_after_rollback.html.erb' => 'active_record_after_rollback',
      'dummy/active_job.html.erb' => 'active_job',
      'dummy/resque.html.erb' => 'resque',
      'dummy/delayed_job.html.erb' => 'delayed_job'
    )
  ]

  def index; end

  def crash
    raise AirbrakeTestError
  end

  def notify_airbrake_helper
    notify_airbrake(AirbrakeTestError.new)
  end

  def notify_airbrake_sync_helper
    notify_airbrake_sync(AirbrakeTestError.new)
  end

  def active_record_after_commit
    Book.create(title: 'Bingo')
  end

  def active_record_after_rollback
    Book.transaction do
      Book.create(title: 'Bango')
      raise ActiveRecord::Rollback
    end
  end

  def active_job
    BingoJob.perform_later('bango', 'bongo')
  end

  def resque
    Resque.enqueue(BingoWorker, 'bango', 'bongo')
  end

  def delayed_job
    Delayed::Job.enqueue(BangoJob.new('bingo', 'bongo'))
  end
end

# Initializes middlewares and such.
DummyApp.initialize!

ActiveRecord::Base.connection.create_table(:books) do |t|
  t.string(:title)
end

ActiveRecord::Migration.verbose = false

# Modified version of: https://goo.gl/q8uCJq
migration_template = File.open(
  File.join(
    $LOAD_PATH.grep(/delayed_job/)[0],
    'generators/delayed_job/templates/migration.rb'
  )
)

# need to eval the template with the migration_version intact
migration_context = Class.new do
  # rubocop:disable Naming/AccessorMethodName
  def get_binding
    binding
  end
  # rubocop:enable Naming/AccessorMethodName

  def migration_version
    return unless ActiveRecord::VERSION::MAJOR >= 5
    "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
  end
end

migration_ruby =
  ERB.new(migration_template.read).result(migration_context.new.get_binding)
migration_template.close
# rubocop:disable Security/Eval
eval(migration_ruby)
# rubocop:enable Security/Eval

ActiveRecord::Schema.define do
  CreateDelayedJobs.up
end
