class TrackersStatusesActivities < ActiveRecord::Base
  unloadable
  belongs_to :tracker
  belongs_to :issue
  belongs_to :issue_status, class_name: 'IssueStatus',  foreign_key: "status_id"
  safe_attributes 'tracker_id', 'status_id', 'activity'
  attr_accessible 'tracker_id', 'status_id', 'activity'
end
