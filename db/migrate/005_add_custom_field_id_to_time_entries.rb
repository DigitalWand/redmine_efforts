class AddCustomFieldIdToTimeEntries < ActiveRecord::Migration
  def change
    add_column :time_entries, :custom_field_id, :integer, :default => 7 # default "Внутренняя оценка"
  end
end
