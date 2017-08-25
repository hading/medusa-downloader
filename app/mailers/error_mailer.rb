class ErrorMailer < ApplicationMailer

  default to: DownloaderConfig.admin_email
  default subject: 'Medusa Downloader error'
  default from: 'no-reply@medusa.illinois.edu'

  def parsing_error(message)
    @message = message
    mail
  end

end
