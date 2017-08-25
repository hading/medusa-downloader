Then(/^an error message should be emailed to the admin$/) do
  open_email(DownloaderConfig.admin_email)
  x = current_emails
  expect(current_emails.size).to eq(1)
  expect(current_emails.first.subject).to eq('Medusa Downloader error')
  expect(current_emails.first.body).to match('JSON parsing error')
end
