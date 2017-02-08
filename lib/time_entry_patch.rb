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

        #Если найти соотвутствующие хуки в контроллерах, то можно выводить флеш-сообщения, генерируемые моделью, пользователям
        def flash
          @flash ||= nil
        end

        protected

        #Функция вызываемая в момент валидации модели. Именно тут проверяем все данные которые пользователь хочет запихнуть в базу
        def check_and_correct_activity
          #return true unless new_record? || changed?
          if new_record?
            tracker = Tracker.find issue.tracker_id_was
            status = IssueStatus.find issue.status_id_was
            at = TrackersStatusesActivities.where(tracker_id: tracker.id, status_id: status.id).first.activity
            if at == "<-->"
              errors.add :base, "Задать трудозатраты для задачи c трекером '#{tracker.name}' и статусом '#{status.name}' нельзя"
            else
              self.active_type = at
              correct_hours
            end
          else
            correct_hours if changed? && changed.include?('hours')
            errors.add :base, "Редактировать тип активности недопустимо" if active_type_changed?
          end
        end

        #Вспомагательные методы модели, упрощающие доступ к кастомному полю
        def active_type
          @custom_field_active_type_id ||= CustomField.find(Setting.plugin_activity['activity_field']).id
          @active_type ||= custom_field_values.select{|item| item.custom_field_id == @custom_field_active_type_id}.shift
        end

        def active_type=(value)
          active_type.value = value
        end

        def active_type_changed?
          active_type.value != active_type.value_was
        end

        def correct_hours
          return if issue.estimated_hours.to_f == 0 # Если лимит не указан, то лимита нет
          # оставшееся время = лимит времени - (потраченное время + списываемое время)
          available_limit = issue.estimated_hours * Setting.plugin_activity['max_ratio'].to_f - (issue.total_spent_hours - (hours_was||0))
          time_left = (available_limit - hours).round(1)
          if (time_left) < 0
            errors.add :base, "нельзя отметить #{hours} часов. Оставшийся лимит часов по задаче: #{available_limit}"
          end
        end
      end
    end
  end
end

unless TimeEntry.included_modules.include?(Activity::Patches::TimeEntryPatch)
  TimeEntry.send(:include, Activity::Patches::TimeEntryPatch)
end



