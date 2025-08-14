class Admin::ReviewsController < Admin::BaseController
  def index
    @date = params[:date]&.to_date || Date.current
    @family = current_adult.family
    
    # Apply child filter if specified
    children_scope = @family.children
    children_scope = children_scope.where(id: params[:child_id]) if params[:child_id].present?
    
    # Get all chore completions for today
    @pending_chore_completions = ChoreCompletion.joins(:child)
                                                .where(child: children_scope)
                                                .where(assigned_date: @date)
                                                .where(reviewed_at: nil)
                                                .includes(:chore, :child)
                                                .order(:created_at)
    
    # Get all extra completions for today that need review  
    @pending_extra_completions = ExtraCompletion.joins(:child)
                                               .where(child: children_scope)
                                               .where(created_at: @date.beginning_of_day..@date.end_of_day)
                                               .where(status: [:completed])
                                               .includes(:extra, :child)
                                               .order(:created_at)
    
    # Get already reviewed items for today
    @reviewed_chore_completions = ChoreCompletion.joins(:child)
                                                .where(child: children_scope)
                                                .where(assigned_date: @date)
                                                .where.not(reviewed_at: nil)
                                                .includes(:chore, :child)
                                                .order(:reviewed_at)
    
    @reviewed_extra_completions = ExtraCompletion.joins(:child)
                                                .where(child: children_scope)
                                                .where(created_at: @date.beginning_of_day..@date.end_of_day)
                                                .where(status: [:approved, :rejected])
                                                .includes(:extra, :child)
                                                .order(:updated_at)
  end
  
  def approve_chore
    @completion = ChoreCompletion.find(params[:id])
    authorize_completion!(@completion)
    
    @completion.mark_reviewed_satisfactory!(current_adult)
    if params[:review_notes].present?
      @completion.update!(review_notes: params[:review_notes])
    end
    
    redirect_to admin_reviews_path, notice: "#{@completion.chore.name} approved for #{@completion.child.name}!"
  end
  
  def reject_chore
    @completion = ChoreCompletion.find(params[:id])
    authorize_completion!(@completion)
    
    notes = params[:review_notes] || "Needs to be redone"
    @completion.mark_reviewed_unsatisfactory!(current_adult, notes)
    
    redirect_to admin_reviews_path, notice: "#{@completion.chore.name} rejected for #{@completion.child.name}. They can try again."
  end
  
  def reset_chore
    @completion = ChoreCompletion.find(params[:id])
    authorize_completion!(@completion)
    
    @completion.update!(
      status: :pending,
      completed_at: nil,
      reviewed_at: nil,
      reviewed_by: nil,
      review_notes: params[:review_notes] || "Please redo this chore"
    )
    
    redirect_to admin_reviews_path, notice: "#{@completion.chore.name} reset for #{@completion.child.name} to try again."
  end
  
  def approve_extra
    @completion = ExtraCompletion.find(params[:id])
    authorize_extra_completion!(@completion)
    
    @completion.approve!(current_adult, params[:notes])
    
    redirect_to admin_reviews_path, notice: "#{@completion.extra.title} approved for #{@completion.child.name}! They earned $#{sprintf('%.2f', @completion.earned_amount)}."
  end
  
  def reject_extra
    @completion = ExtraCompletion.find(params[:id])
    authorize_extra_completion!(@completion)
    
    notes = params[:notes] || "Not completed satisfactorily"
    @completion.reject!(current_adult, notes)
    
    redirect_to admin_reviews_path, notice: "#{@completion.extra.title} rejected for #{@completion.child.name}."
  end
  
  private
  
  def authorize_completion!(completion)
    unless completion.child.family == current_adult.family
      redirect_to admin_dashboard_index_path, alert: "You can only review your family's chores."
    end
  end
  
  def authorize_extra_completion!(completion)
    unless completion.child.family == current_adult.family
      redirect_to admin_dashboard_index_path, alert: "You can only review your family's extras."
    end
  end
end