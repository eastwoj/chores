class AddExcludeExtrasTodayToFamilySettings < ActiveRecord::Migration[8.0]
  def change
    add_column :family_settings, :exclude_extras_today, :boolean, default: false, null: false
  end
end
