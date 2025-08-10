class Admin::DashboardController < Admin::BaseController
  def index
    authorize :admin_dashboard, :index?
    
    @family = current_adult.family
    @children = @family.children.active
    @today_chore_lists = ChoreList.joins(:child)
                                  .where(child: @children, start_date: Date.current, interval: :daily)
                                  .includes(:chore_completions, :child)
    
    # Get pending review counts for the dashboard button
    @pending_chore_completions = ChoreCompletion.joins(:child)
                                                .where(child: @family.children)
                                                .where(assigned_date: Date.current)
                                                .where(completed_at: ..Time.current)
                                                .where(reviewed_at: nil)
    
    @pending_extra_completions = ExtraCompletion.joins(:child)
                                               .where(child: @family.children)
                                               .where(created_at: Date.current.beginning_of_day..Date.current.end_of_day)
                                               .where(status: [:completed])
  end
end