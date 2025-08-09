class Admin::BaseController < ApplicationController
  before_action :authenticate_adult!
  before_action :authorize_admin_access!

  private

  def pundit_user
    current_adult
  end

  def authorize_admin_access!
    authorize :admin, :access?
  rescue Pundit::NotAuthorizedError
    flash[:alert] = "You don't have permission to access the admin area."
    redirect_to root_path
  end
end