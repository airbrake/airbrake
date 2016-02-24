require 'sinatra/base'

class SinatraApp1 < Sinatra::Base
  get('/') { raise AirbrakeTestError }
end

Airbrake.configure(SinatraApp1) do |c|
  c.project_id = 113743
  c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
  c.logger = Logger.new('/dev/null')
end
