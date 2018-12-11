# config valid only for current version of Capistrano
lock '3.11.0'

set :application, 'medusa-downloader'
set :repo_url, 'https://github.com/medusa-project/medusa-downloader.git'

set :bin, "#{fetch(:home)}/bin"
set :rails_env, 'production'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml', 'config/medusa_downloader.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')
set :linked_dirs, fetch(:linked_dirs, []).push('log')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  namespace :deploy do
    task :restart do
      on roles(:web) do
        execute 'monit -g medusa restart'
      end
    end
  end

  after 'deploy:publishing', 'deploy:restart'

end

def execute_rake(task)
  on roles(:app) do
    within release_path do
      with rails_env: fetch(:rails_env) do
        execute :rake, task
      end
    end
  end
end
