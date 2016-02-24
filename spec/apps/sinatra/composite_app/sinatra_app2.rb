require 'sinatra/base'

class SinatraApp2 < Sinatra::Base
  get('/') { raise AirbrakeTestError }
end

Airbrake.configure(SinatraApp2) do |c|
  c.project_id = 99123
  c.project_key = 'ad04e13d806a90f96614ad8e529b2821'
  c.logger = Logger.new('/dev/null')
end
