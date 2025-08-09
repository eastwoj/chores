class ChildKioskController < ApplicationController
  def index
    @children = Child.all
  end

  def show
    @child = Child.find(params[:id])
    @today_chore_list = @child.daily_chore_lists.find_by(date: Date.current)
  end
end