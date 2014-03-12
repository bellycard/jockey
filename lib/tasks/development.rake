namespace :development do
  desc "Print out a docker CLI command with a config set"
  task :docker_run, [:app_name, :env_name] => :environment do |t, args|
    config = Jockey::ConfigSet.get(app: args[:app_name],
                                   environment: args[:env_name],
                                   github_access_token: ENV['GITHUB_OAUTH_TOKEN']).data.first.config
    config_string = ''
    config.each do |k,v|
      config_string << " -e #{k}=\"#{v}\""
    end
    puts "docker run #{config_string} IMAGE_ID /start web"
  end
end
