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

          has_one :type_costs, class_name: 'IssueCustomField', primary_key: 'custom_field_id', foreign_key: 'id'
        end
      end

      module InstanceMethods

        # Если найти соотвутствующие хуки в контроллерах, то можно выводить флеш-сообщения, генерируемые моделью, пользователям
        def flash
          @flash ||= nil
        end

        protected

        # Получим "свои" роли на проекте
        def my_roles
          @my_roles ||= self.project.users_by_role.map do |role, users|
            if users.map(&:id).include?(self.user.id).present?
              role
            end
          end.compact
        end

        # Записывает трудозатраты руководства и тестирования
        def select_active_type(default)
          # self.type_costs # что за затрата
          # self.project.users_by_role # все роли с юзерами на проекте
          # self.user # Кто оставил запись

          if my_roles.count == 1 # Одна роль на проекте
            # activities = TrackersStatusesActivities.where(tracker_id: tracker.id).where('activity <> "" AND activity <> "<-->"').map(&:activity).uniq
            # TODO: Завести таблицу по связке роли и активности!!! + приоритет ролей
            # ["Non member", "Anonymous", "Менеджер", "Разработчик", "Администратор", "Клиент", "Тестировщик", "Тимлид", "Дизайнер", "Редактор"]
            # ["работа по задаче", "тестирование", "консультации", "правка багов"]
            if my_roles.first.name == "Тимлид"
              return TrackersStatusesActivities.where(activity: 'руководство').uniq.first.activity
            elsif my_roles.first.name == "Тестировщик"
              return TrackersStatusesActivities.where(activity: 'тестирование').uniq.first.activity
            else
              return default
            end
          elsif my_roles.count > 1 # пока не знаем что делать, оставляем как есть
            return default
          end

        end

        def is_exceeding_estimate
          return if issue.new_record? or issue.message_of_exceeding_estimate # Не отправлять если новое или уже отправлено
          settings = Setting[SETTINGS_NAME] || {}
          limit = (settings['limit'] || 0).to_f
          # если текущая оценка + лимит превышает запланированную, то
          if (issue.time_entries.map(&:hours).sum + limit) > issue.estimated_internal
              role_ids = (settings['roles'] || []).map(&:to_i)
              recipients = project. # Все те кому отправить письмо счастья
                           members.
                           joins(:roles).
                           where('roles.id in (?)', role_ids).
                           includes(:user).
                           uniq.
                           map(&:user)

              recipients.each do |recipient|
                EstimateMailer.exceeding_estimate_mail(recipient, issue).deliver
              end
              issue.update_column(:message_of_exceeding_estimate, true)
          end
        end

        # Функция вызываемая в момент валидации модели. Именно тут проверяем все данные которые пользователь хочет запихнуть в базу
        def check_and_correct_activity
          if new_record?
            tracker = Tracker.find issue.tracker_id_was
            status = IssueStatus.find issue.status_id_was
            at = TrackersStatusesActivities.where(tracker_id: tracker.id, status_id: status.id).first.activity
            if at == "<-->"
              errors.add :base, "Задать трудозатраты для задачи c трекером '#{tracker.name}' и статусом '#{status.name}' нельзя"
            else
              self.active_type = self.active_type.to_s.blank? ? select_active_type(at) : at
              correct_hours
            end
          else
            correct_hours if changed? && changed.include?('hours')
            errors.add :base, "Редактировать тип активности недопустимо" if active_type_changed?
          end
        end

        # Вспомагательные методы модели, упрощающие доступ к кастомному полю
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
          max_ratio = Setting[SETTINGS_NAME]['max_ratio'].to_f

          available_limit = if my_roles.count == 1 # Одна роль на проекте
            if (my_roles.first.name == "Тимлид") and (self.active_type.to_s == 'руководство') #TODO: ВНИМАНИЕ ПЕРПИСАТЬ НА СВЯЗИ!!
              ratio_control = Setting[SETTINGS_NAME][RATIO_CONTROL].to_f
              # оставшееся время = лимит времени на руководство * коэффициент - (потраченное время * коф руководства)
              issue.estimated_control * max_ratio  - (issue.total_spent_hours - (hours_was||0)) * ratio_control
            elsif (my_roles.first.name == "Тестировщик") and (self.active_type.to_s == 'тестирование') #TODO: ВНИМАНИЕ ПЕРПИСАТЬ НА СВЯЗИ!!
              ratio_test =  Setting[SETTINGS_NAME][RATIO_TEST].to_f
              # оставшееся время = лимит времени на тустировщика * коэффициент - (потраченное время * коф тестирования)
              issue.estimated_testing * max_ratio - (issue.total_spent_hours - (hours_was||0)) * ratio_test
            else
              issue.estimated_internal * max_ratio - (issue.total_spent_hours - (hours_was||0))
            end
          else my_roles.count > 1 # пока не знаем что делать, оставляем как есть....
            issue.estimated_internal * max_ratio - (issue.total_spent_hours - (hours_was||0))
          end

          time_left = (available_limit - hours).round(2)
          if (time_left) < 0
            errors.add :base, l('can_not_be_noted', {
                hours: hours.round(2),
                limit: available_limit.round(2)
            })
          end
        end
      end
    end
  end
end

unless TimeEntry.included_modules.include?(Efforts::Patches::TimeEntryPatch)
  TimeEntry.send(:include, Efforts::Patches::TimeEntryPatch)
end
