class AdminUserMailer < ActionMailer::Base
  default from: Rails.configuration.noreply_email

  def password_reset(user)
    mail to: user.email
  end
end
