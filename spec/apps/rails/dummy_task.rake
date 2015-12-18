# Keep this before any task definitions to collect extra info about tasks.
# Without this line the tests will fail.
Rake::TaskManager.record_task_metadata = true

namespace :bingo do
  # This task contains *maximum* amount of information.
  desc 'Dummy description'
  task :bango, [:dummy_arg] => [:environment] do |_t, _args|
    raise AirbrakeTestError
  end

  # This task contains *minimum* amount of information.
  task :bongo do
    raise AirbrakeTestError
  end

  task :environment do
    # No-op.
  end
end
