namespace :hoptoad do
  desc "Fire off a test exception to make sure Hoptoad's installed correctly"
  task :test => :environment do
    require 'action_controller/test_process'
    require 'application'

    request = ActionController::TestRequest.new
    request.env['REQUEST_METHOD'] = 'GET'
    request.action = 'test_hoptoad'

    response = ActionController::TestResponse.new

    controller = ApplicationController.new
    def controller.test_hoptoad; raise 'Testing hoptoad via "rake hoptoad:test"'; end
    controller.class.action_methods << 'test_hoptoad'

    controller.process(request, response)
  end
end
