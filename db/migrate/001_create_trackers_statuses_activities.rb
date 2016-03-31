class CreateTrackersStatusesActivities < ActiveRecord::Migration
  def change
    create_table :trackers_statuses_activities do |t|
      t.integer :tracker_id
      t.integer :status_id
      t.string :activity
    end
    add_index :trackers_statuses_activities, [:tracker_id, :status_id], :unique => true
  end
end
