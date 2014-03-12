require 'honeybadger/rake_handler'

Honeybadger.configure do |config|
  config.rescue_rake_exceptions = true
  config.environment_name = Rails.env
  config.api_key = ENV['HONEYBADGER_API_KEY']
end
