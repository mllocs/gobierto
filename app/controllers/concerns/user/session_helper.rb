module User::SessionHelper
  extend ActiveSupport::Concern

  private

  def current_user
    @current_user ||= find_current_user
  end

  def user_signed_in?
    current_user.present?
  end

  def sign_in_user(user_id)
    session[:user_id] = user_id
  end

  def sign_out_user
    @current_user = session[:user_id] = nil
  end

  def authenticate_user!
    raise_user_not_signed_in unless user_signed_in?
  end

  def find_current_user
    User.confirmed.find_by(id: session[:user_id])
  end

  def after_sign_in_path
    root_path
  end

  def after_sign_out_path
    root_path
  end

  def raise_user_not_signed_in
    redirect_to(
      new_user_sessions_path,
      alert: "We need you to sign in to continue."
    )
  end

  def raise_user_not_authorized
    redirect_to(
      request.referrer || user_root_path,
      alert: "You are not authorized to perform this action."
    )
  end
end
