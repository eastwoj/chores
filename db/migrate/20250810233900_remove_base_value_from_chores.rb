class RemoveBaseValueFromChores < ActiveRecord::Migration[8.0]
  def change
    remove_column :chores, :base_value, :decimal
  end
end
