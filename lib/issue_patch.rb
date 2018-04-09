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
          before_save :update_estimated_internal
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

        # Обновляет внутренние трудозатраты если в статусе новая и трудозатраты не одинаковые
        def update_estimated_internal
          if self.persisted? and self.status_id == 1 and self.estimated_internal != self.estimated_hours
            self.update({estimated_internal: self.estimated_hours})
          end
        end

      end
    end
  end
end

unless Issue.included_modules.include?(Efforts::Patches::TimeEntryPatch)
  Issue.send(:include, Efforts::Patches::IssuePatch)
end
