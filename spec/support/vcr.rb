VCR.configure do |c|
  c.cassette_library_dir = './spec/vcr'
  c.hook_into :webmock
  c.filter_sensitive_data('<HEADER_PASSWORD>') { ENV['HEADER_PASSWORDS'] }
  c.filter_sensitive_data('<CONSUL_SERVER_URL>') { ENV['CONSUL_SERVER_URL'] }
  c.filter_sensitive_data('<DOCKER_SERVICE_NAME>') { ENV['DOCKER_SERVICE_NAME'] }
end

RSpec.configure do |c|
  c.around(:each, :vcr) do |example|
    name = example.metadata[:full_description].split(/\s+/, 2).join('/').underscore.gsub(/[^\w\/]+/, '_')
    options = example.metadata.slice(:record, :match_requests_on).except(:example_group)
    VCR.use_cassette(name, options) { example.call }
  end
end
