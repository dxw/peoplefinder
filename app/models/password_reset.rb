class PasswordReset
  include ActiveModel::Validations
  include ActiveModel::Conversion

  validate :admin_user_with_email_must_exist

  attr_accessor :email, :user

  def initialize(opts = {})
    @email = opts[:email]
    @user  = User.find_admin_by_email(@email)
  end

  def save
    return false unless valid?
    identity.initiate_password_reset!
  end

  def token
    identity.password_reset_token
  end

private

  def identity
    @user.primary_identity
  end

  def admin_user_with_email_must_exist
    errors.add(:base, 'No admin user with that email exists') if @user.nil?
  end
end
