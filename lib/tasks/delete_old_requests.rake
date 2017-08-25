require 'rake'

namespace :downloader do
  desc 'Delete old requests and associated file system resources'
  task :delete_old_requests => :environment do
    Request.where('updated_at < ?', Time.now - 14.days).find_each do |request|
      request.destroy!
    end
    #prune the directory tree - this removes empty directories working from the leaves up
    Dir.chdir(DownloaderConfig.instance.storage_path) do
      system("find . -type d -empty -delete")
    end
  end

end