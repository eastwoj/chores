class AddRequireChoresForExtrasToFamilySettings < ActiveRecord::Migration[8.0]
  def change
    add_column :family_settings, :require_chores_for_extras, :boolean, default: false, null: false
  end
end
