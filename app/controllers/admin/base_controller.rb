class Admin::BaseController < ApplicationController
  before_action :authenticate_adult!

  private

  def pundit_user
    current_adult
  end
end