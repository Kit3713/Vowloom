class ImportantAnnouncementsMailer < ApplicationMailer
  def announcement(post, recipient)
    @post = post
    @recipient = recipient
    @site = post.site

    mail(
      to: recipient.recovery_email,
      subject: "#{@site.name}: #{post.title.presence || "Important wedding announcement"}"
    )
  end
end
