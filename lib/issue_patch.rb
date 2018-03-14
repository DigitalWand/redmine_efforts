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
        end
      end

      module InstanceMethods
        def estimated_internal
          @custom_field_estimated_id ||= CustomField.find(Setting.plugin_efforts['estimated_field']).id
          @estimated_internal ||= custom_field_values.select{|item| item.custom_field_id == @custom_field_estimated_id}.shift
          @estimated_internal.nil? ? 0.to_f : @estimated_internal.value.to_f
        end

        def estimated_internal=(value)
          @estimated_internal.value = value.to_f if !@estimated_internal.nil?
        end

        protected

        def set_estimated_internal
          self.estimated_internal = self.estimated_hours if self.estimated_internal.to_int == 0
          unless self.estimated_hours.nil?
            if self.estimated_hours <= 0.0
              errors.add :base, "Оценка времени не может быть равна '#{self.estimated_hours}'!"
            end
          end
        end

      end
    end
  end
end

unless Issue.included_modules.include?(Efforts::Patches::TimeEntryPatch)
  Issue.send(:include, Efforts::Patches::IssuePatch)
end



