require 'fileutils'
class Request < ActiveRecord::Base

  attr_accessor :storage_root

  has_one :manifest_creation, dependent: :destroy

  STATUSES = %w(pending creating_manifest ready missing_or_invalid_targets)

  validates :status, inclusion: STATUSES, allow_blank: false

  after_destroy :delete_manifest_and_links

  def download_url
    "#{Config.nginx_url}/downloads/#{root}/#{downloader_id}/get"
  end

  def status_url
    "#{Config.nginx_url}/downloads/#{root}/#{downloader_id}/status"
  end

  def manifest_url
    "#{Config.nginx_url}/downloads/#{root}/#{downloader_id}/manifest"
  end

  def has_manifest?
    File.exist?(manifest_path)
  end

  def storage_path
    File.join(Config.instance.storage_path, relative_storage_path)
  end

  def relative_storage_path
    prefix_dirs = downloader_id.first(6).chars.in_groups_of(2).collect(&:join)
    File.join(*prefix_dirs, downloader_id)
  end

  def manifest_path
    File.join(storage_path, 'manifest.txt')
  end

  def tar_manifest_path
    File.join(storage_path, 'tar_manifest.csv')
  end

  def delete_manifest_and_links
    FileUtils.rm_rf(storage_path) if Dir.exist?(storage_path)
  end

  def generate_manifest_and_links
    self.status = 'creating_manifest'
    self.save!
    manifest_generator = get_manifest_generator
    manifest_generator.generate_manifest_and_links
    self.total_size = manifest_generator.total_size
    self.status = 'ready'
    self.save!
  end

  def set_status_for_missing_or_invalid_targets
    File.delete(manifest_path) if File.exist?(manifest_path)
    self.status = 'missing_or_invalid_targets'
    self.save!
  end

  STATUSES.each do |status|
    define_method :"#{status}?" do
      self.status == status
    end
  end

  def ensure_storage_root
    self.storage_root ||= MedusaDownloader::Application.storage_roots.at(self.root)
  end

  def manifest_generator_class
    case ensure_storage_root
    when MedusaStorage::Root::Filesystem
      ManifestGenerator::Filesystem
    when MedusaStorage::Root::S3
      ManifestGenerator::S3
    else
      raise "No ManifestGenerator for provided storage root type"
    end
  end

  def get_manifest_generator
    manifest_generator_class.new(request: self, storage_root: ensure_storage_root)
  end


end
