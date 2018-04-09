#!/bin/env ruby
# encoding: utf-8
require_dependency 'time_entry'

module Efforts
  module Patches
    module TimeEntryPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          validate :check_and_correct_activity
          after_save :is_exceeding_estimate
        end
      end

      module InstanceMethods

        # Если найти соотвутствующие хуки в контроллерах, то можно выводить флеш-сообщения, генерируемые моделью, пользователям
        def flash
          @flash ||= nil
        end

        protected

        def is_exceeding_estimate
          return if issue.new_record? or issue.message_of_exceeding_estimate # Не отправлять если новое или уже отправлено
          settings = Setting[SETTINGS_NAME] || {}
          limit = (settings['limit'] || 0).to_f
          # если текущая оценка + лимит превышает запланированную, то
          if (issue.time_entries.map(&:hours).sum + limit) > issue.estimated_internal
              role_ids = (settings['roles'] || []).map(&:to_i)
              # puts "!!! estimate: им: #{role_ids}"
              recipients = project. # Все те кому отправить письмо счастья
                           members.
                           joins(:roles).
                           where('roles.id in (?)', role_ids).
                           includes(:user).
                           uniq.
                           map(&:user)
              # puts "!!! список имен: #{recipients.map(&:name)}"

              recipients.each do |recipient|
                EstimateMailer.exceeding_estimate_mail(recipient, issue).deliver
              end
              issue.update_column(:message_of_exceeding_estimate, true)
          end
        end

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
          @custom_field_active_type_id ||= CustomField.find(Setting[SETTINGS_NAME]['activity_field']).id
          @active_type ||= custom_field_values.select{|item| item.custom_field_id == @custom_field_active_type_id}.shift
        end

        def active_type=(value)
          active_type.value = value
        end

        def active_type_changed?
          active_type.value != active_type.value_was
        end

        def correct_hours
          return if issue.estimated_internal == 0 # Если лимит не указан, то лимита нет
          # оставшееся время = лимит времени - (потраченное время + списываемое время)
          available_limit = issue.estimated_internal * Setting[SETTINGS_NAME]['max_ratio'].to_f - (issue.total_spent_hours - (hours_was||0))
          time_left = (available_limit - hours).round(1)
          if (time_left) < 0
            errors.add :base, "Нельзя отметить #{hours} часов. Оставшийся лимит часов по задаче: #{available_limit}. Обратитесь к тимлиду или менеджеру. "
          end
        end
      end
    end
  end
end

unless TimeEntry.included_modules.include?(Efforts::Patches::TimeEntryPatch)
  TimeEntry.send(:include, Efforts::Patches::TimeEntryPatch)
end
