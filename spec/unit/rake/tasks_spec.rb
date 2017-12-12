require 'spec_helper'

RSpec.describe "airbrake/rake/tasks" do
  let(:endpoint) do
    'https://airbrake.io/api/v4/projects/113743/deploys?key=fd04e13d806a90f96614ad8e529b2822'
  end

  def wait_for_a_request_with_body(body)
    wait_for(a_request(:post, endpoint).with(body: body)).to have_been_made.once
  end

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
  end

  describe "airbrake:deploy" do
    let(:task) { Rake::Task['airbrake:deploy'] }

    after { task.reenable }

    shared_examples 'deploy payload' do |key, val|
      it "sends #{key}" do
        ENV[key.upcase] = val
        task.invoke

        wait_for_a_request_with_body(/{.*"#{key}":"#{val}".*}/)
        ENV[key.upcase] = nil
      end
    end

    [%w[environment production],
     %w[username john],
     %w[revision 123abcdef],
     %w[repository https://github.com/airbrake/airbrake'],
     %w[version v2.0]].each do |(key, val)|
      include_examples 'deploy payload', key, val
    end

    context "when Airbrake is not configured" do
      let(:deploy_endpoint) { 'https://airbrake.io/api/v3/projects/113743/notices' }

      before do
        stub_request(:post, deploy_endpoint)
        expect(Airbrake).to receive(:configured?).and_return(false)
      end

      it "raises error" do
        expect { task.invoke }.
          to raise_error(Airbrake::Error, 'airbrake-ruby is not configured')
      end
    end
  end

  describe "airbrake:install_heroku_deploy_hook" do
    let(:task) { Rake::Task['airbrake:install_heroku_deploy_hook'] }

    after { task.reenable }

    let(:airbrake_vars) { "AIRBRAKE_PROJECT_ID=1\nAIRBRAKE_API_KEY=2\nRAILS_ENV=3\n" }
    let(:silenced_stdout) { File.new(File::NULL, 'w') }

    before do
      @original_stdout = $stdout
      $stdout = silenced_stdout
    end

    after do
      $stdout.close
      $stdout = @original_stdout
    end

    describe "parsing environment variables" do
      it "does not raise when an env variable value contains '='" do
        heroku_config = airbrake_vars + "URL=https://airbrake.io/docs?key=11\n"
        expect(Bundler).to receive(:with_clean_env).twice.and_return(heroku_config)

        task.invoke
      end
    end
  end
end
