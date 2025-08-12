class Admin::HistoryController < Admin::BaseController
  def index
    authorize :admin_dashboard, :index?
    
    @family = current_adult.family
    @children = @family.children.active.includes(:chore_completions)
    
    # Date filtering
    @start_date = parse_date_param(params[:start_date]) || 30.days.ago.to_date
    @end_date = parse_date_param(params[:end_date]) || Date.current
    
    # Child filtering
    @selected_child_id = params[:child_id].present? ? params[:child_id].to_i : nil
    @selected_child = @selected_child_id ? @children.find(@selected_child_id) : nil
    
    # Status filtering
    @selected_status = params[:status].presence
    
    # Build the query
    @chore_completions = build_chore_completions_query
                          .includes(:chore, :child, :reviewed_by)
                          .order(assigned_date: :desc, created_at: :desc)
                          .limit(100)
    
    # Summary statistics
    @summary_stats = calculate_summary_statistics
  end
  
  private
  
  def parse_date_param(date_string)
    return nil if date_string.blank?
    Date.parse(date_string)
  rescue ArgumentError
    nil
  end
  
  def build_chore_completions_query
    query = ChoreCompletion.joins(:child)
                           .where(child: @family.children)
                           .where(assigned_date: @start_date..@end_date)
    
    # Filter by child if specified
    query = query.where(child_id: @selected_child_id) if @selected_child_id
    
    # Filter by status if specified
    query = query.where(status: @selected_status) if @selected_status
    
    query
  end
  
  def calculate_summary_statistics
    base_query = ChoreCompletion.joins(:child)
                                .where(child: @family.children)
                                .where(assigned_date: @start_date..@end_date)
    
    # Apply same filters as main query
    base_query = base_query.where(child_id: @selected_child_id) if @selected_child_id
    base_query = base_query.where(status: @selected_status) if @selected_status
    
    {
      total_chores: base_query.count,
      completed_chores: base_query.where(status: [:completed, :reviewed_satisfactory, :reviewed_unsatisfactory]).count,
      pending_chores: base_query.where(status: :pending).count,
      satisfactory_chores: base_query.where(status: :reviewed_satisfactory).count,
      unsatisfactory_chores: base_query.where(status: :reviewed_unsatisfactory).count,
      needs_review: base_query.where(status: :completed).count
    }
  end
end