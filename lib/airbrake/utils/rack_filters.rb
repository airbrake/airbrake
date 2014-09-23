module Airbrake
  SENSITIVE_RACK_VARS = %w(
      HTTP_X_CSRF_TOKEN
      HTTP_COOKIE

      action_dispatch.request.unsigned_session_cookie
      action_dispatch.cookies
      action_dispatch.unsigned_session_cookie
      action_dispatch.secret_key_base
      action_dispatch.signed_cookie_salt
      action_dispatch.encrypted_cookie_salt
      action_dispatch.encrypted_signed_cookie_salt
      action_dispatch.http_auth_salt
      action_dispatch.secret_token

      rack.request.cookie_hash
      rack.request.cookie_string
      rack.request.form_vars

      rack.session
      rack.session.options
  )

  RACK_VARS_CONTAINING_INSTANCES = %w(
      action_controller.instance

      action_dispatch.backtrace_cleaner
      action_dispatch.routes
      action_dispatch.logger
      action_dispatch.key_generator

      rack-cache.storage

      rack.errors
      rack.input
  )

  SENSITIVE_ENV_VARS = [
      /secret/i,
      /password/i
  ]

  FILTERED_RACK_VARS = SENSITIVE_RACK_VARS + SENSITIVE_ENV_VARS + RACK_VARS_CONTAINING_INSTANCES
end
