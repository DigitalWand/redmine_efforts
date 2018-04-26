#!/bin/env ruby
# encoding: utf-8
require_dependency 'issue'

module Efforts
  module Patches
    module IssuePatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          validate :set_estimated_internal
          before_save :message_status_check
          before_save :update_estimated
        end
      end

      module InstanceMethods
        def estimated_internal
          @custom_field_estimated_id ||= CustomField.find(Setting[SETTINGS_NAME]['estimated_field']).id
          @estimated_internal ||= custom_field_values.select{|item| item.custom_field_id == @custom_field_estimated_id}.shift
          @estimated_internal.nil? ? 0.to_f : @estimated_internal.value.to_f
        end

        def estimated_internal=(value)
          @estimated_internal.value = value.to_f if !@estimated_internal.nil?
        end

        # Возвращает оценку тестирования
        def estimated_testing
          @custom_field_estimated_testing_id ||= CustomField.find_by_id(Setting[SETTINGS_NAME][RATIO_TEST_ID]).try(:id)
          @estimated_testing ||= custom_field_values.select{|item| item.custom_field_id == @custom_field_estimated_testing_id}.shift
          @estimated_testing.try(:value).to_f
        end

        # Устанавливает оценку тестирования
        def estimated_testing=(value)
          @estimated_testing.value = value.to_f if !@estimated_testing.nil?
        end

        # Возвращает оценку руководства
        def estimated_control
          @custom_field_estimated_control_id ||= CustomField.find_by_id(Setting[SETTINGS_NAME][RATIO_CONTROL_ID]).try(:id)
          @estimated_control ||= custom_field_values.select{|item| item.custom_field_id == @custom_field_estimated_control_id}.shift
          @estimated_control.try(:value).to_f
        end

        # Устанавливает оценку руководства
        def estimated_control=(value)
          @estimated_control.value = value.to_f if !@estimated_control.nil?
        end

        protected

        # Устанавливает статус отправки писем участникам о превышении трудозатрат
        def message_status_check
          if !self.new_record? and self.estimated_internal != Issue.find_by_id(id).try(:estimated_internal) # изменилась оценка
            self.update_column(:message_of_exceeding_estimate, false)
          end
        end

        # Устанавливает внутренние трудозатраты если запись новая и трудозатраты не выставлены
        def set_estimated_internal
          if self.new_record? or self.estimated_internal.to_int == 0
            self.estimated_internal = self.estimated_hours # if self.estimated_internal.to_int == 0
          end
        end

        # Обновляет оценку трудозатрат
        def update_estimated
          update_data = {}

          if self.persisted? and self.status_id == 1
            # Обновляем оценку трудозатрат, если не одинаковые
            if self.estimated_internal != self.estimated_hours
              update_data.merge!({estimated_internal: self.estimated_hours})
            end

            # Обновляем оценку трудозатрат для тестирования, если еще в статусе новая (и трудозатраты не пересчитаны)
            estimated_testing = self.estimated_hours * Setting[SETTINGS_NAME][RATIO_TEST].to_f
            if self.estimated_testing != estimated_testing
              update_data.merge!({estimated_testing: estimated_testing})
            end

            # Обновляем оценку трудозатрат для руководства, если еще в статусе новая (и трудозатраты не пересчитаны)
            estimated_control = self.estimated_hours * Setting[SETTINGS_NAME][RATIO_CONTROL].to_f
            if self.estimated_control != estimated_control
              update_data.merge!({estimated_control: estimated_control})
            end
          end

          if update_data.present?
            self.update(update_data)
          end
        end

      end
    end
  end
end

unless Issue.included_modules.include?(Efforts::Patches::TimeEntryPatch)
  Issue.send(:include, Efforts::Patches::IssuePatch)
end
