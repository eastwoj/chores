class Admin::DashboardController < Admin::BaseController
  def index
    authorize :admin_dashboard, :index?
    
    @family = current_adult.family
    @children = @family.children.active
    @today_chore_lists = ChoreList.joins(:child)
                                  .where(child: @children, start_date: Date.current, interval: :daily)
                                  .includes(:chore_completions, :child)
  end
end