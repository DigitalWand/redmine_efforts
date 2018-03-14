class CreateTrackersStatusesActivities < ActiveRecord::Migration
  def change
    create_table :trackers_statuses_activities do |t|
      t.integer :tracker_id
      t.integer :status_id
      t.string :activity
    end
    add_index :trackers_statuses_activities, [:tracker_id, :status_id], :unique => true

    reversible do |change|
      change.up do
        cf = TimeEntryCustomField.new
        cf.name = "Activities"
        cf.field_format = 'list'
        cf.possible_values = ['estimate','work','test','fix']
        cf.is_filter = 1
        cf.save!
      end
    end
  rescue => e
    puts "ERROR: #{e}"
  end
end
