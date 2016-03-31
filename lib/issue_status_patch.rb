
#!/bin/env ruby
# encoding: utf-8
require_dependency 'issue_status'
require_dependency 'trackers_statuses_activities'

module Activity
  module Patches
    module IssueStatusPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development

          has_many :trackers_statuses_activities, class_name: 'TrackersStatusesActivities',  foreign_key: "status_id"
        end
      end

      module InstanceMethods

      end
    end
  end
end

unless IssueStatus.included_modules.include?(Activity::Patches::IssueStatusPatch)
  IssueStatus.send(:include, Activity::Patches::IssueStatusPatch)
end
