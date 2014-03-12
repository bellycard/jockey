# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# create some environments
development = Environment.create!(name: :development)
staging = Environment.create!(name: :staging)
production = Environment.create!(name: :production)

# create some stacks
api_stack = Stack.create!(name: :api)
build_stack = Stack.create!(name: :build)

# create some apps
test_app = App.create!(name: 'jockey-sample-app',
                       subscribe_to_github_webhook: false,
                       repo: 'bellycard/jockey-sample-app',
                       stack: api_stack)

# update our config set
test_app_config = ConfigSet.where(app: test_app,
                                  environment: development).first
test_app_config.config['DATABASE_URL'] = 'mysql2://root:root@172.17.42.1/jockey_sample_app'
test_app_config.save!

test_app.workers.where(environment: development).update_all(scale: 2, command: 'bundle exec puma -C ./config/puma.rb')

# create app entry for jockey
jockey_app = App.create!(name: 'jockey',
                         subscribe_to_github_webhook: false,
                         repo: 'bellycard/jockey',
                         stack: api_stack)
# app ENV to jockey's config set
jockey_config = ConfigSet.where(app: jockey_app, environment: development).first
ENV.each do |k,v|
  jockey_config.config[k] = v
end
jockey_config.save!
