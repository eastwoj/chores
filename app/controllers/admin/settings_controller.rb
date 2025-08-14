class Admin::SettingsController < Admin::BaseController
  before_action :set_family_setting

  def show
  end

  def update
    if @family_setting.update(family_setting_params)
      redirect_to admin_settings_path, notice: "Settings updated successfully!"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_family_setting
    @family_setting = current_adult.family.family_setting || current_adult.family.create_family_setting!
  end

  def family_setting_params
    params.require(:family_setting).permit(
      :payout_frequency,
      :payout_day,
      :auto_approve_after_hours,
      :payout_interval_days,
      :require_chores_for_extras,
      :exclude_extras_today
    )
  end
end