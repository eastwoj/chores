class Admin::ChoresController < Admin::BaseController
  before_action :set_chore, only: [:show, :edit, :update, :destroy, :toggle_active]
  before_action :set_family, only: [:index, :new, :create, :assign_constant_chore, :remove_constant_assignment, :generate_daily_lists]

  def index
    authorize :admin, :index?
    @chores = @family.chores.includes(:assigned_children).order(:title)
    @children = @family.children.active.order(:first_name)
  end

  def show
    authorize @chore, :show?
  end

  def new
    @chore = @family.chores.build
    authorize @chore, :new?
  end

  def create
    @chore = @family.chores.build(chore_params)
    authorize @chore, :create?

    if @chore.save
      redirect_to admin_chores_path, notice: "Chore was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @chore, :edit?
  end

  def update
    authorize @chore, :update?

    if @chore.update(chore_params)
      redirect_to admin_chores_path, notice: "Chore was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @chore, :destroy?
    @chore.destroy
    redirect_to admin_chores_path, notice: "Chore was successfully deleted."
  end

  def toggle_active
    authorize @chore, :update?
    
    if @chore.active?
      @chore.deactivate!
      message = "#{@chore.title} has been deactivated."
    else
      @chore.activate!
      message = "#{@chore.title} has been activated."
    end
    
    redirect_to admin_chores_path, notice: message
  end

  def assign_constant_chore
    authorize :admin, :manage_chores?
    
    chore = @family.chores.find(params[:chore_id])
    child = @family.children.find(params[:child_id])
    
    if chore.constant?
      chore.chore_assignments.find_or_create_by!(child: child, active: true)
      flash[:notice] = "#{chore.title} assigned to #{child.name}."
    else
      flash[:alert] = "Only constant chores can be manually assigned."
    end
    
    redirect_to admin_chores_path
  end

  def remove_constant_assignment
    authorize :admin, :manage_chores?
    
    assignment = ChoreAssignment.find(params[:assignment_id])
    assignment.destroy
    
    flash[:notice] = "Chore assignment removed."
    redirect_to admin_chores_path
  end

  def generate_daily_lists
    authorize :admin, :manage_chores?
    
    @family.generate_daily_chore_lists
    flash[:notice] = "Daily chore lists generated successfully for all children."
    redirect_to admin_root_path
  end

  private

  def set_chore
    @chore = current_adult.family.chores.find(params[:id])
  end

  def set_family
    @family = current_adult.family
  end

  def chore_params
    params.require(:chore).permit(:title, :description, :instructions, :chore_type, :difficulty, 
                                  :estimated_minutes, :min_age, :max_age, :base_value, :active)
  end
end