require 'pathname'
Before do
  AmqpConnector.instance.clear_queues('client_to_downloader_test', 'downloader_to_client_test')
  Pathname.new(DownloaderConfig.instance.storage_path).children.each {|child| child.rmtree} rescue nil
end