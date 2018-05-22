class StorageRoot::S3 < StorageRoot
  attr_accessor :bucket, :region, :prefix, :aws_access_key_id, :aws_secret_access_key

  def initialize(args = {})
    super(args)
    self.bucket = args[:bucket]
    self.region = args[:region]
    self.prefix = args[:prefix] || ''
    self.aws_access_key_id = args[:aws_access_key_id]
    self.aws_secret_access_key = args[:aws_secret_access_key]
  end

  def manifest_generator_class
    ManifestGenerator::S3
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(region: region, credentials: s3_credentials)
  end

  def s3_credentials
    Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
  end

  def presigner
    @presigner ||= Aws::S3::Presigner.new(client: s3_client)
  end

  def info(key)
    s3_client.head_object(bucket: bucket, key: key)
  end

  def size(key)
    info(key).content_length
  end

  def presigned_get_url(key, args = {})
    presigner.presigned_url(:get_object, {bucket: bucket, key: key, expires_in: 7.days_to_i}.merge(args))
  end

  def file_keys(directory_key)
    internal_subtree_keys(directory_key, delimiter: '/')
  end

  def subtree_keys(directory_key)
    internal_subtree_keys(directory_key)
  end

  def subdirectory_keys(directory_key)
    Array.new.tap do |keys|
      continuation_token = nil
      loop do
        results = s3_client.list_objects_v2(bucket: bucket, prefix: ensure_directory_key(directory_key), continuation_token: continuation_token, delimiter: delimiter)
        keys += results.common_prefixes.collect(&:key)
        continuation_token = results.next_continuation_token
        break if continuation_token.nil?
      end
    end
  end

  def internal_subtree_keys(directory_key, delimiter: nil)
    Array.new.tap do |keys|
      continuation_token = nil
      loop do
        results = s3_client.list_objects_v2(bucket: bucket, prefix: ensure_directory_key(directory_key), continuation_token: continuation_token, delimiter: delimiter)
        keys += results.contents.collect(&:key).reject {|key| directory_key?(key)}
        continuation_token = results.next_continuation_token
        break if continuation_token.nil?
      end
    end
  end

  def directory_key?(key)
    key.end_with?('/')
  end

  def ensure_directory_key(key)
    directory_key?(key) ? key : key + '/'
  end

end