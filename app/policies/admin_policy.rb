class AdminPolicy < ApplicationPolicy
  def access?
    user_is_authorized_adult?
  end

  def index?
    access?
  end

  def show?
    access?
  end

  def create?
    user_is_admin_or_parent?
  end

  def update?
    user_is_admin_or_parent?
  end

  def destroy?
    user_is_admin_or_parent?
  end

  def manage_chores?
    user_is_admin_or_parent?
  end

  private

  def user_is_authorized_adult?
    return false unless user.is_a?(Adult)
    
    # Allow access to adults with admin, parent, or guardian roles
    user.has_role?("admin") || user.has_role?("parent") || user.has_role?("guardian")
  end

  def user_is_admin_or_parent?
    return false unless user.is_a?(Adult)
    
    # More restrictive - only admin or parent can create/update/destroy
    user.has_role?("admin") || user.has_role?("parent")
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.is_a?(Adult) && (user.has_role?("admin") || user.has_role?("parent") || user.has_role?("guardian"))
        scope.all
      else
        scope.none
      end
    end
  end
end