class TrackersStatusesActivitiesController < ApplicationController
  unloadable

  require 'issue_status'

  def index
    @tracker = params[:tracker] ? Tracker.find(params[:tracker]) : Tracker.first
    @statuses = IssueStatus.connection.select_all("Select s.id, s.name, a.id as activity_id, a.activity as activity from issue_statuses as s
        left outer join trackers_statuses_activities as a on (s.id = a.status_id and a.tracker_id = #{@tracker.id})").to_hash
    @activities = TimeEntryCustomField.find_by_name(Setting.plugin_activity['activity_field']).possible_values.unshift('<-->')
  end

  def mass_update
    tracker_id = params[:tracker].to_i
    params[:status].each do |key, value|
      if (activity = TrackersStatusesActivities.where(tracker_id: tracker_id, status_id: key.to_i).first)
        activity.activity = value
        activity.save
      else
        TrackersStatusesActivities.create(tracker_id: tracker_id, status_id: key.to_i, activity: value)
      end
    end
    redirect_to trackers_statuses_activities_path(tracker_id: tracker_id)
  end

end
