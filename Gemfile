source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.5'
# Use postgresql as the database for Active Record
gem 'pg', '0.17.1', :platform => :jruby, :git => 'git://github.com/headius/jruby-pg.git', :branch => :master
#gem 'pg', '~> 0.17', platform: :ruby

# Use SCSS for stylesheets
gem 'sass-rails'
gem 'less-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby
gem 'therubyrhino', platforms: :jruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc'

gem 'passenger'
gem 'bunny'
gem 'haml-rails'
gem 'delayed_job_active_record'
gem 'daemons'
gem 'twitter-bootstrap-rails'
gem 'font-awesome-rails'
gem 'rpairtree', require: 'pairtree'
#gem 'zip_tricks'
#gem 'zipline'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
#  gem 'byebug'
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
end

group :test do
  gem 'rspec-rails'
  gem 'cucumber-rails', require: false
  gem 'shoulda'
  gem 'factory_girl'
  gem 'capybara'
  gem 'capybara-email'
  gem 'database_cleaner'
  gem 'simplecov'
  gem 'json_spec'
  gem 'connection_pool'
end

