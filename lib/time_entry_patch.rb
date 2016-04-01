#!/bin/env ruby
# encoding: utf-8
require_dependency 'time_entry'

module Activity
  module Patches
    module TimeEntryPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          validate :check_and_correct_activity
        end
      end

      module InstanceMethods

        protected

        def check_and_correct_activity
          #return true unless new_record? || changed?
          if new_record?
            a_active_type = TrackersStatusesActivities.where(tracker_id: issue.tracker_id, status_id: issue.status_id).first.activity
            if a_active_type == "<-->"
              errors.add :base, "Задать трудозатраты для данного статуса задачи невозможно"
            else
              self.active_type = a_active_type
              correct_hours
            end
          else
            correct_hours if changed? && changed.include?('hours')
            errors.add :base, "Редактировать тип активности недопустимо" if active_type_changed?
          end
        end

        def active_type
          set_activity_type_field
        end

        def active_type=(value)
          set_activity_type_field
          @active_type.value = value
        end

        def active_type_changed?
          set_activity_type_field
          !(@active_type.value == @active_type.value_was)
        end

        def set_activity_type_field
          @custom_field_active_type_id ||= CustomField.find_by_name(Setting.plugin_activity['activity_field']).id
          @active_type ||= custom_field_values.select{|item| item.custom_field_id == @custom_field_active_type_id}.shift
        end

        def correct_hours
          if (diff = (issue.total_spent_hours - (hours_was||0) + hours - issue.estimated_hours * Setting.plugin_activity['max_ratio'].to_f).round(1))>0
            self.hours -= diff
            @flash = "Трудозатраты уменьшены до максимально приемлемого уровня"
          end
        end

        def flash
          @flash ||= nil
        end
      end
    end
  end
end

unless TimeEntry.included_modules.include?(Activity::Patches::TimeEntryPatch)
  TimeEntry.send(:include, Activity::Patches::TimeEntryPatch)
end



