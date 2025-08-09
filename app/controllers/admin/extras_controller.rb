class Admin::ExtrasController < Admin::BaseController
  before_action :set_extra, only: [:show, :edit, :update, :destroy, :toggle_active]
  before_action :set_family, only: [:index, :new, :create, :assign_extra, :remove_extra_assignment]

  def index
    authorize :admin, :index?
    @extras = @family.extras.includes(:assigned_children).order(:title)
    @children = @family.children.active.order(:first_name)
  end

  def show
    authorize @extra, :show?
  end

  def new
    @extra = @family.extras.build
    @extra.available_from = Date.current
    @extra.available_until = 1.week.from_now.to_date
    authorize @extra, :new?
  end

  def create
    @extra = @family.extras.build(extra_params)
    authorize @extra, :create?

    if @extra.save
      redirect_to admin_extras_path, notice: "Extra was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @extra, :edit?
  end

  def update
    authorize @extra, :update?

    if @extra.update(extra_params)
      redirect_to admin_extras_path, notice: "Extra was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @extra, :destroy?
    @extra.destroy
    redirect_to admin_extras_path, notice: "Extra was successfully deleted."
  end

  def toggle_active
    authorize @extra, :update?
    
    if @extra.active?
      @extra.deactivate!
      message = "#{@extra.title} has been deactivated."
    else
      @extra.activate!
      message = "#{@extra.title} has been activated."
    end
    
    redirect_to admin_extras_path, notice: message
  end

  def assign_extra
    authorize :admin, :manage_chores?
    
    extra = @family.extras.find(params[:extra_id])
    child = @family.children.find(params[:child_id])
    
    extra.extra_assignments.find_or_create_by!(child: child, active: true)
    flash[:notice] = "#{extra.title} assigned to #{child.name}."
    
    redirect_to admin_extras_path
  end

  def remove_extra_assignment
    authorize :admin, :manage_chores?
    
    assignment = ExtraAssignment.find(params[:assignment_id])
    assignment.destroy
    
    flash[:notice] = "Extra assignment removed."
    redirect_to admin_extras_path
  end

  private

  def set_extra
    @extra = current_adult.family.extras.find(params[:id])
  end

  def set_family
    @family = current_adult.family
  end

  def extra_params
    params.require(:extra).permit(:title, :description, :reward_amount, 
                                  :available_from, :available_until, 
                                  :max_completions, :active)
  end
end