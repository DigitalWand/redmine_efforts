#!/bin/env ruby
# encoding: utf-8
#call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })
module Activity
  class ControllerTimelogEditBeforeSaveHook < Redmine::Hook::ViewListener
    def controller_timelog_edit_before_save(context={})
      # Если получится, то вставить обработчик флеш-сообщений
    end
  end
end