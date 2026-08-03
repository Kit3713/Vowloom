require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Local persistent disk is the self-hosted default. Set ACTIVE_STORAGE_SERVICE=s3
  # to use a compatible object store such as MinIO; see config/storage.yml.
  config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", "local").to_sym

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ENV["FORCE_SSL"] == "true"

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  # config.cache_store = :mem_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # config.active_job.queue_adapter = :resque

  # Email is opt-in and disabled by default. Providing an SMTP address enables
  # delivery for account recovery and important announcements. This prevents a
  # fresh self-hosted install from attempting an unexpected external connection.
  smtp_address = ENV["VOWLOOM_SMTP_ADDRESS"].presence
  smtp_enabled = smtp_address.present?
  config.action_mailer.delivery_method = smtp_enabled ? :smtp : :test
  config.action_mailer.perform_deliveries = smtp_enabled
  config.action_mailer.raise_delivery_errors = smtp_enabled
  if smtp_enabled
    config.action_mailer.smtp_settings = {
      address: smtp_address,
      port: ENV.fetch("VOWLOOM_SMTP_PORT", 587).to_i,
      user_name: ENV["VOWLOOM_SMTP_USERNAME"],
      password: ENV["VOWLOOM_SMTP_PASSWORD"],
      authentication: ENV.fetch("VOWLOOM_SMTP_AUTHENTICATION", "plain").to_sym,
      enable_starttls_auto: ENV.fetch("VOWLOOM_SMTP_STARTTLS", "true") == "true"
    }
  end

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = {
    host: ENV.fetch("VOWLOOM_HOST", "localhost"),
    protocol: ENV.fetch("FORCE_SSL", "false") == "true" ? "https" : "http"
  }

  # Limit browser and WebSocket requests to the configured public host. Local
  # loopback hosts remain available for an on-server health check and a fresh
  # Compose installation before DNS is configured.
  public_host = ENV.fetch("VOWLOOM_HOST", "localhost")
  allowed_hosts = [ public_host, "localhost", "127.0.0.1", "::1" ].uniq
  config.hosts = allowed_hosts
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
  allowed_protocols = ENV["FORCE_SSL"] == "true" ? [ "https" ] : [ "http", "https" ]
  config.action_cable.allowed_request_origins = allowed_hosts.product(allowed_protocols).map do |host, protocol|
    "#{protocol}://#{host}"
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]
end
