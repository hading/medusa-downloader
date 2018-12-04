require 'csv'
class ManifestGenerator::Base

  attr_accessor :storage_root, :request, :file_list, :total_size
  delegate :storage_path, :manifest_path, :targets, to: :request

  def initialize(args = {})
    self.storage_root = args[:storage_root]
    self.request = args[:request]
  end

  def generate_manifest_and_links
    FileUtils.mkdir_p(File.dirname(manifest_path))
    FileUtils.mkdir_p(data_path)
    generate_file_list
    write_file_list_and_compute_size
  end

  #create from the targets a list of files to be included and also their destinations in the zip file and sizes
  #throw an error if a file/directory does not exist, if it is outside of the root, if the target type is invalid,
  #etc.
  def generate_file_list
    self.file_list = Concurrent::Array.new
    CSV.open(request.tar_manifest_path, 'w') do |tar_manifest_csv|
      targets.each do |target|
        add_target(target, tar_manifest_csv)
      end
    end
  end

  def data_path
    File.join(storage_path, 'data')
  end

  def literal_path
    File.join(storage_path, 'literal')
  end

  def relative_path_to(absolute_path)
    absolute_path.sub(/^#{Config.instance.storage_path}/, '')
  end

  def add_target(target, tar_manifest_csv)
    case target['type']
    when 'file'
      add_file(target, tar_manifest_csv)
    when 'directory'
      add_directory(target, tar_manifest_csv)
    when 'literal'
      add_literal(target, tar_manifest_csv)
    else
      raise InvalidTargetTypeError.new(target)
    end
  end

  def add_literal(target, tar_manifest_csv)
    FileUtils.mkdir_p(literal_path)
    file = new_literal_file
    File.open(file, 'w') do |f|
      f.write(target['content'])
    end
    path = target['zip_path'] || ''
    name = target['name'] || (raise RuntimeError "Name must be provided for literal content.")
    zip_file_path = File.join(path, name)
    self.file_list << [file, zip_file_path, File.size(file), true]
    tar_manifest_csv << ['literal', zip_file_path, nil, target['content']]
  end

  def new_literal_file
    name = File.join(literal_path, SecureRandom.hex(6))
    File.exist?(name) ? literal_file_name : name
  end

end