class WaitlistMailer < ApplicationMailer
  def approval_email(waitlist_entry)
    @waitlist_entry = waitlist_entry
    @access_pass = waitlist_entry.access_pass
    @space = @access_pass.space

    mail(
      to: @waitlist_entry.email,
      subject: "You've been approved for #{@space.name}!"
    )
  end
end
