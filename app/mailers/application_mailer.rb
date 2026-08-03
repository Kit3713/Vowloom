class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("VOWLOOM_MAIL_FROM", "Vowloom <no-reply@localhost>")
  layout "mailer"
end
