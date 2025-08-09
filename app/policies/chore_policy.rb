class ChorePolicy < ApplicationPolicy
  def show?
    user_is_family_member?
  end

  def new?
    user_is_admin_or_parent?
  end

  def create?
    user_is_admin_or_parent?
  end

  def edit?
    user_is_admin_or_parent?
  end

  def update?
    user_is_admin_or_parent?
  end

  def destroy?
    user_is_admin_or_parent?
  end

  private

  def user_is_family_member?
    return false unless user.is_a?(Adult)
    
    # Allow access to adults who belong to the same family as the chore
    user.family_id == record.family_id
  end

  def user_is_admin_or_parent?
    return false unless user.is_a?(Adult)
    return false unless user_is_family_member?
    
    # More restrictive - only admin or parent can manage chores
    user.has_role?("admin") || user.has_role?("parent")
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.is_a?(Adult)
        # Adults can only see chores from their own family
        scope.where(family: user.family)
      else
        scope.none
      end
    end
  end
end