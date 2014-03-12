source 'https://rubygems.org'
ruby '2.0.0'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.1.4'
gem 'dotenv-rails'

gem 'mysql2'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

gem 'napa', github: 'bellycard/napa'
gem 'napa_pagination'
gem 'hashie_rails'
gem 'roar-rails'
gem 'docker-api', require: 'docker'
gem 'omniauth-github'
gem 'activerecord-session_store'
gem 'rails_admin', github: 'bellycard/rails_admin'
gem 'paper_trail', '~> 3.0.3'
gem 'git'
gem 'crud_client'
gem 'paranoia', '~> 2.0'
gem 'render_anywhere', require: false
gem 'slack-notifier'
gem 'rb-readline'
gem 'newrelic_rpm'

group :production, :staging do
  gem 'honeybadger'
  gem 'unicorn-rails'
  gem 'rails_12factor'
end

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
group :development do
  gem 'spring'
  gem 'better_errors'
  gem 'binding_of_caller'
end

group :test do
  gem 'database_cleaner'
  gem 'simplecov'
  gem 'vcr'
  gem 'webmock'
  gem 'bullet'
  gem 'test_after_commit'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'pry'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'spring-commands-rspec'
end
