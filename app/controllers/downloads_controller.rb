require 'open3'
require 'csv'
class DownloadsController < ApplicationController

  include ActionController::Live
  # include ZipTricks::RailsStreaming
  # include ActionController::Streaming
  #include Zipline

  before_action :get_request, only: %i(get status manifest download download_tar)
  skip_before_action :verify_authenticity_token, only: :create

  def get
    if @request.ready?
      response.headers['X-Archive-Files'] = 'zip'
      send_file @request.manifest_path, disposition: :attachment, filename: "#{@request.zip_name}.zip"
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
  #           real_path = File.join(Config.instance.storage_path, content_path)
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
  #       real_path = File.join(Config.instance.storage_path, content_path)
  #       [file_struct.new(real_path), zip_path]
  #     end
  #     zipline(files, "#{@request.zip_name}.zip")
  #   else
  #     render status: :not_found, plain: 'Manifest is not yet ready for this archive'
  #   end
  # end

  def download
    if @request.ready?
      begin
        response.headers['Content-Type'] = 'application/zip'
        response.headers['Content-Disposition'] = %Q(attachment; filename="#{@request.zip_name || @request.downloader_id}.zip")
        t = Thread.new do
          Open3.popen2('java', '-jar', File.join(Rails.root, 'jars', 'clojure-zipper.jar'), @request.manifest_path, Config.instance.storage_path) do |stdin, stdout, wait_thr|
            #buffer = ''
            buffer_size = 1024
            begin
              while true
                buffer = stdout.readpartial(buffer_size)
                response.stream.write(buffer) if buffer.length > 0
              end
            rescue EOFError
              Rails.logger.error "Done reading pipe"
            end
            # while true
            #   result = stdout.read(buffer_size, buffer)
            #   response.stream.write buffer unless result.nil?
            #   break if result.nil? or result.length == 0
            # end
            # while !stdout.eof?
            #   stdout.readpartial(buffer_size, buffer)
            #   unless buffer.nil? or buffer.length.zero?
            #     Rails.logger.error "Read #{buffer}"
            #     response.stream.write(buffer)
            #   end
            # end
            Rails.logger.error wait_thr.value.inspect
          end
        end
        t.join
      ensure
        response.stream.close
      end
    else
      render status: :not_found, plain: 'Manifest is not yet ready for this archive'
    end
  end

  #TODO - create a separate 'tar manifest' that is just target location/key pairs from the storage
  # and whatever for literals. Maybe a CSV of type: content/literal, target, key, literal. One of key/literal will be blank
  # Use that to do this.
  def download_tar
    if @request.ready?
      begin
        response.headers['Content-Type'] = 'application/x-tar'
        filename = "#{@request.zip_name || @request.downloader_id}.tar"
        response.headers['Content-Disposition'] = %Q(attachment; filename=#{filename})
        tar_read_pipe, tar_write_pipe = IO.pipe
        tar_writer = Archive::Tar::Minitar::Writer.open(tar_write_pipe)
        manifest = CSV.open(@request.tar_manifest_path)
        tar_write_thread = Thread.new do
          manifest.each_line do |type, target, key, literal|
            case type
            when 'content'
              tar_writer.add_file(target, mode: 0644, mtime: @request.storage_root.mtime(key)) do |tar_io, opts|
                @request.storage_root.with_output_io(key) do |object_io|
                  IO.copy_stream(object_io, tar_io)
                end
              end
            when 'literal'
              tar_writer.add_file(target, mode: 0644, mtime: Time.now, data: literal)
            else
              raise "Unrecognized type"
            end
          end
        end
        render text: proc {|response, output|
          buffer = ''
          while tar_read_pipe.read(1024, buffer)
            output.write(buffer)
          end
        }
        tar_write_thread.join
      ensure
        response.stream.close
      end
    else
      render status: :notfound, plain: 'Manifest is not yet ready for this archive'
    end
  end

  # def download
  #   if @request.ready?
  #     begin
  #       #TODO: make fifo - for now just use one for testing
  #       pipe_path = File.join(Rails.root, 'pipe')
  #       zip_thread = Thread.new do
  #         begin
  #           pipe_output_stream = FileOutputStream.new(pipe_path)
  #           zip_stream = ZipOutputStream.new(pipe_output_stream)
  #           zip_stream.set_level(0)
  #           manifest = File.open(@request.manifest_path)
  #           manifest.each_line do |line|
  #             line.chomp!
  #             dash, file_size, content_path, zip_path = line.split(' ', 4)
  #             content_path.gsub!(/^\/internal\//, '')
  #             real_path = File.join(DownloaderConfig.instance.storage_path, content_path)
  #             zip_entry = ZipEntry.new(zip_path)
  #             Rails.logger.error(zip_path)
  #             zip_stream.put_next_entry(zip_entry)
  #             input_stream = FileInputStream.new(real_path)
  #             IOUtils.copy_large(input_stream, zip_stream)
  #             Rails.logger.error("DONE: " + zip_path)
  #           end
  #         ensure
  #           pipe_output_stream.close
  #           zip_stream.close
  #         end
  #       end
  #       output_thread = Thread.new do
  #         #f = File.open(pipe_path, File::RDONLY | File::BINARY | File::NONBLOCK)
  #         File.open(pipe_path, 'rb') do |f|
  #           response.headers['Content-Type'] = 'application/zip'
  #           response.headers['Content-Disposition'] = %Q(attachment; filename="#{@request.zip_name || @request.downloader_id}.zip")
  #           size = 1024
  #           buffer = ''
  #           total_bytes = 0
  #           while !f.eof?
  #             f.readpartial(size, buffer)
  #             unless bytes.nil? or bytes.length.zero?
  #               response.stream.write(bytes)
  #               total_bytes += bytes.length
  #               Rails.logger.error "READ #{total_bytes} bytes"
  #             end
  #           end
  #         end
  #       end
  #       zip_thread.join
  #       output_thread.join
  #     ensure
  #       response.stream.close
  #     end
  #   else
  #     render status: :not_found, plain: 'Manifest is not yet ready for this archive'
  #   end``

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
    json_string = request.body.read
    #Request.transaction do
    Rails.logger.info "Creating request from: #{json_string}"
    req = HttpRequestBridge.create_request(json_string)
    Rails.logger.info "Generating manifest for request #{req.downloader_id}"
    req.generate_manifest_and_links
    Rails.logger.info "Generated manifest for request #{req.downloader_id}"
    x = HttpRequestBridge.request_received_ok_message(req).to_json
    render json: HttpRequestBridge.request_received_ok_message(req).to_json, status: 201
      #end
  rescue JSON::ParserError
    Rails.logger.error "Unable to parse request body: #{json_string}"
    render json: {error: 'Unable to parse request body'}.to_json, status: 400
  rescue Request::InvalidRoot
    Rails.logger.error "Invalid root in request: #{json_string}"
    render json: {error: 'Invalid root'}.to_json, status: 400
  rescue MedusaStorage::InvalidKeyError
    Rails.logger.error "Invalid or missing file in request: #{json_string}"
    req.destroy! if req.present?
    render json: {error: 'Invalid or missing file'}.to_json, status: 400
  rescue Exception => e
    Rails.logger.error "Unknown error for request: #{json_string}"
    Rails.logger.error "Error: #{e}"
    Rails.logger.error "Backtrace: #{e.backtrace}"
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
    authenticate_or_request_with_http_digest(Config.auth[:realm]) do |user|
      Config.auth[:users][user]
    end
  end

end