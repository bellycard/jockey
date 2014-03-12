namespace :import do
  desc "Fetch all of the config sets from chef"
  task :config_sets, [:env_name] => :environment do |t, args|
    env_name = args[:env_name]
    raise "no environment name given" unless env_name
    # run this locally where you have access to the data bags
    # set RACK_ENV to production so that you hit the jockey server that is live.
    Dir.new("#{Rails.root}/../chef-repo/data_bags/").each do |d|
      begin
        config_json = `cd ../chef-repo && knife data bag show #{d} #{env_name} --secret-file .chef/encrypted_data_bag_secret -F json`
        # check for an app on jockey that is filename - _config
        app_name = d.gsub('_config', '')
        app = Jockey::App.get(name: app_name, github_access_token: ENV['GITHUB_OAUTH_TOKEN']).data.try(:first)

        if app
          puts "setting #{config_json} on #{app_name} #{env_name}"
          config = JSON.parse(config_json)

          # if the config set is already there, overwrite.
          config_set = Jockey::ConfigSet.get(app: app_name,
                                             environment: env_name,
                                             github_access_token: ENV['GITHUB_OAUTH_TOKEN']).data.first
          if config_set
            Jockey::ConfigSet.put(config_set.id,
                                   app: app_name,
                                   environment: env_name,
                                   config: config,
                                   github_access_token: ENV['GITHUB_OAUTH_TOKEN'])
          else
            # upload config for env_name
            Jockey::ConfigSet.post(app: app_name,
                                   environment: env_name,
                                   config: config,
                                   github_access_token: ENV['GITHUB_OAUTH_TOKEN'])
          end
        end
      rescue => e
        puts e
      end
    end
  end

  desc "Fetch all of the apps from the chef recipes"
  task :apps => :environment do |t, args|
    # run this locally where you have access to the recipes
    # set RACK_ENV to production so that you hit the jockey server that is live.
    Dir.new("#{Rails.root}/../chef-repo/cookbooks/belly-service/recipes/").each do |d|
      begin
        next unless d.include?('.rb')
        # get the name of the app from the filename
        app_name = d.gsub('.rb', '')

        # check to see if the app is already there
        app = Jockey::App.get(name: app_name, github_access_token: ENV['GITHUB_OAUTH_TOKEN']).data.try(:first)

        unless app
          puts "creating app #{app_name}"
          Jockey::App.post(name: app_name,
                           repo: "bellycard/#{app_name}",
                           subscribe_to_github_webhook: false,
                           github_access_token: ENV['GITHUB_OAUTH_TOKEN'])
        end
      rescue => e
        puts e
      end
    end
  end
end
