class DownloadsController < ApplicationController

  include ActionController::Live
  #include ActionController::Streaming

  java_import java.io.BufferedOutputStream
  java_import java.io.BufferedInputStream
  java_import java.util.zip.ZipOutputStream
  java_import java.util.zip.ZipEntry
  java_import java.io.PipedOutputStream
  java_import java.io.PipedInputStream

  require File.join(Rails.root, 'jars/commons-io-2.5.jar')
  java_import org.apache.commons.io.IOUtils

  before_filter :get_request, only: %i(get status manifest download)
  if DownloaderConfig.instance.auth_active?
    before_filter :authenticate, only: :create
  end
  skip_before_filter :verify_authenticity_token, only: :create

  def get
    if @request.ready?
      response.headers['X-Archive-Files'] = 'zip'
      send_file @request.manifest_path, disposition: :attachment, filename: "#{@request.zip_name}.zip"
    else
      render status: :not_found, plain: 'Manifest is not yet ready for this archive'
    end
  end


  BUFFER_SIZE=1024
  def download
    if @request.ready?
      begin
        pipe = PipedOutputStream.new
        result = PipedInputStream.new
        pipe.connect(result)
        zip_stream = ZipOutputStream.new(pipe)
        zip_stream.set_level(0)
        manifest = File.open(@request.manifest_path)
        copy_thread = Thread.new do
          manifest.each_line do |line|
            line.chomp!
            dash, size, content_path, zip_path = line.split(' ', 4)
            content_path.gsub!(/^\/internal\//, '')
            real_path = File.join(DownloaderConfig.instance.storage_path, content_path)
            zip_entry = ZipEntry.new(zip_path)
            zip_stream.put_next_entry(zip_entry)
            input_stream = File.open(real_path, 'rb').to_inputstream
            IOUtils.copy_large(input_stream, zip_stream)
          end
          zip_stream.close
        end
        response.headers['Content-Type'] = 'application/zip'
        buffer = Java::byte[BUFFER_SIZE].new
        while (bytes_read = result.read(buffer)) != -1
          response.stream.write String.from_java_bytes(buffer).first(bytes_read)
        end
      ensure
        response.stream.close
      end
    else
      render status: :not_found, plain: 'Manifest is not yet ready for this archive'
    end
  end


# def download
#   if @request.ready?
#     manifest = File.open(@request.manifest_path)
#     zip_tricks_stream do |zip|
#       manifest.each_line do |line|
#         line.chomp!
#         dash, size, content_path, zip_path = line.split(' ', 4)
#         content_path.gsub!(/^\/internal\//, '')
#         zip.write_stored_file(zip_path) do |target|
#           real_path = File.join(DownloaderConfig.instance.storage_path, content_path)
#           Rails.logger.error("Content: #{real_path}, Zip: #{zip_path}, Size: #{size}")
#           File.open(real_path, 'rb') do |source|
#             IO.copy_stream(source, target)
#           end
#         end
#       end
#     end
#   else
#     render status: :not_found, plain: 'Manifest is not yet ready for this archive'
#   end
# end

# def download
#   if @request.ready?
#     manifest = File.open(@request.manifest_path)
#     file_struct = Struct.new(:file)
#     files = manifest.each_line.collect do |line|
#       line.chomp!
#       dash, size, content_path, zip_path = line.split(' ', 4)
#       content_path.gsub!(/^\/internal\//, '')
#       real_path = File.join(DownloaderConfig.instance.storage_path, content_path)
#       [file_struct.new(real_path), zip_path]
#     end
#     zipline(files, "#{@request.zip_name}.zip")
#   else
#     render status: :not_found, plain: 'Manifest is not yet ready for this archive'
#   end
# end


def status

end

def manifest
  if @request.ready?
    send_file @request.manifest_path, disposition: :inline, type: 'text/plain'
  else
    render status: :not_found, plain: 'Manifest is not yet ready for this archive'
  end
end

def create
  Request.transaction do
    json_string = request.body.read
    req = HttpRequestBridge.create_request(json_string)
    req.generate_manifest_and_links
    render json: HttpRequestBridge.request_received_ok_message(req).to_json, status: 201
  end
rescue JSON::ParserError
  render json: {error: 'Unable to parse request body'}.to_json, status: 400
rescue Request::InvalidRoot
  render json: {error: 'Invalid root'}.to_json, status: 400
rescue InvalidFileError
  render json: {error: 'Invalid or missing file'}.to_json, status: 400
rescue Exception
  render json: {error: 'Unknown error'}.to_json, status: 500
end

protected

def get_request
  @request = Request.find_by(downloader_id: params[:id])
  #TODO require root
  if @request.blank? or (params[:root] != @request.root)
    render status: :not_found, plain: 'Requested archive not found'
  end
end

def authenticate
  authenticate_or_request_with_http_digest(DownloaderConfig.auth[:realm]) do |user|
    DownloaderConfig.auth[:users][user]
  end
end

end
