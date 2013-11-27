class SendJob
  include SuckerPunch::Job if defined?(SuckerPunch)

  def perform(notice)
    Airbrake.sender.send_to_airbrake(notice)
  end
end
