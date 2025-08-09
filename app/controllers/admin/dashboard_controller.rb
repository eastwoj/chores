class Admin::DashboardController < Admin::BaseController
  def index
    authorize :admin_dashboard, :index?
    
    @family = current_adult.family
    @children = @family.children
    @today_chore_lists = @family.daily_chore_lists.includes(:child, :chore_completions).where(date: Date.current)
  end
end