class ChildKioskController < ApplicationController
  def index
    @children = Child.all
  end

  def show
    @child = Child.find(params[:id])
    @viewing_date = params[:date] ? Date.parse(params[:date]) : Date.current
    @today_chore_list = find_daily_chore_list(@viewing_date)
    @available_extras = should_show_extras? ? find_available_extras : []
    @show_celebration = params[:celebration] == "true"
    @viewing_yesterday = @viewing_date == Date.current - 1.day
  end

  def complete_chore
    @child = Child.find(params[:id])
    completion = ChoreCompletion.find(params[:completion_id])
    
    # Verify this completion belongs to this child
    if completion.child == @child && completion.assigned_date == Date.current
      completion.mark_completed!
      
      # Check if all chores are now completed
      chore_list = @child.chore_lists.find_by(start_date: Date.current, interval: :daily)
      if chore_list && chore_list.all_completed?
        flash[:notice] = "🎉 AMAZING! You completed ALL your chores today! 🎉"
        redirect_to child_kiosk_path(@child, celebration: true)
        return
      else
        flash[:notice] = "Great job! You completed #{completion.chore.title}!"
      end
    else
      flash[:alert] = "Something went wrong. Please try again."
    end

    redirect_to child_kiosk_path(@child)
  end

  def uncomplete_chore
    @child = Child.find(params[:id])
    completion = ChoreCompletion.find(params[:completion_id])
    
    # Verify this completion belongs to this child and is completed but not yet reviewed
    if completion.child == @child && completion.assigned_date == Date.current && completion.completed? && !completion.reviewed_at?
      completion.mark_uncompleted!
      flash[:notice] = "#{completion.chore.title} marked as not complete. You can redo it when ready."
    else
      flash[:alert] = "Cannot uncheck this chore."
    end

    redirect_to child_kiosk_path(@child)
  end

  def complete_extra
    @child = Child.find(params[:id])
    extra = Extra.find(params[:extra_id])
    
    # Verify this extra is assigned to this child and available
    if @child.assigned_extras.include?(extra) && extra.can_be_completed_by?(@child)
      # Check if already completed today
      existing = extra.extra_completions.find_by(child: @child, created_at: Date.current.all_day)
      
      unless existing
        extra.extra_completions.create!(
          child: @child,
          status: :completed,
          completed_at: Time.current,
          earned_amount: extra.reward_amount
        )
        flash[:notice] = "Awesome! You completed #{extra.title} and earned $#{sprintf('%.2f', extra.reward_amount)}!"
      else
        flash[:alert] = "You already completed this extra today."
      end
    else
      flash[:alert] = "This extra is not available to you right now."
    end

    redirect_to child_kiosk_path(@child)
  end

  private

  def should_show_extras?
    # Only show extras for current day, not yesterday
    return false unless @viewing_date == Date.current
    
    family_setting = @child.family.family_setting
    
    # Check if extras are excluded for today
    return false if family_setting&.exclude_extras_today
    
    # If setting is off, always show extras
    return true unless family_setting&.require_chores_for_extras
    
    # If setting is on, only show extras if all chores are completed
    return false unless @today_chore_list&.chore_completions&.any?
    
    @today_chore_list.chore_completions.all?(&:completed?)
  end

  def find_daily_chore_list(date = Date.current)
    # Find existing chore list for the given date - don't auto-generate
    @child.chore_lists.includes(:chore_completions, chores: []).find_by(
      start_date: date,
      interval: :daily
    )
  end

  def find_available_extras
    # Get assigned extras that are active and available today
    @child.assigned_extras
          .active
          .current
          .includes(:extra_completions)
          .map do |extra|
      # Check if child has any pending/completed extras for today
      today_completion = extra.extra_completions.find_by(child: @child, created_at: Date.current.all_day)
      
      {
        extra: extra,
        completion: today_completion,
        can_complete: today_completion.nil? && extra.can_be_completed_by?(@child)
      }
    end
  end
end