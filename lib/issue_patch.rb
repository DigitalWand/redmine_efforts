#!/bin/env ruby
# encoding: utf-8
require_dependency 'issue'

module Activity
  module Patches
    module IssuePatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          # validate :check_and_correct_activity
        end
      end

      module InstanceMethods
        def estimated_internal
          @custom_field_estimated_id ||= CustomField.find(Setting.plugin_activity['estimated_field']).id
          @estimated_internal ||= custom_field_values.select{|item| item.custom_field_id == @custom_field_estimated_id}.shift
          @estimated_internal.value
        end
      end
    end
  end
end

unless Issue.included_modules.include?(Activity::Patches::TimeEntryPatch)
  Issue.send(:include, Activity::Patches::IssuePatch)
end



