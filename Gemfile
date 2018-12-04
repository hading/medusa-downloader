source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.0'
# Use postgresql as the database for Active Record
gem 'pg'
# Use SCSS for stylesheets
gem 'sass-rails'
gem 'less-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
#gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', group: :doc

gem 'passenger'
gem 'bunny'
gem 'haml-rails'
gem 'delayed_job_active_record'
gem 'daemons'
gem 'twitter-bootstrap-rails', '~> 3.2.2'
gem 'font-awesome-rails'
gem 'rpairtree', require: 'pairtree'
gem 'zip_tricks'
gem 'zipline'
gem 'minitar'
gem 'nokogiri'

gem 'medusa_storage', git: 'https://github.com/medusa-project/medusa_storage.git', branch: 'master'

gem 'concurrent-ruby', require: 'concurrent'
gem 'parallel'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-cucumber'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console'
  gem 'capistrano-rails', group: :development
  gem 'capistrano-bundler'
  gem 'capistrano-rbenv'
  gem 'puma'
end

group :test do
  gem 'rspec-rails'
  gem 'cucumber-rails', require: false
  gem 'shoulda'
  gem 'factory_bot'
  gem 'capybara'
  gem 'capybara-email'
  gem 'database_cleaner'
  gem 'simplecov'
  gem 'json_spec'
  gem 'connection_pool'
end

