class AddAssignedDateToChoreCompletions < ActiveRecord::Migration[8.0]
  def change
    add_column :chore_completions, :assigned_date, :date
    add_index :chore_completions, [:child_id, :assigned_date]
  end
end
