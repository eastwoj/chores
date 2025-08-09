class AdminDashboardPolicy < ApplicationPolicy
  def index?
    user_is_adult_with_admin_access?
  end

  def show?
    index?
  end

  private

  def user_is_adult_with_admin_access?
    return false unless user.is_a?(Adult)
    
    # Check if adult has admin, parent, or guardian roles
    user.has_role?("admin") || user.has_role?("parent") || user.has_role?("guardian")
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