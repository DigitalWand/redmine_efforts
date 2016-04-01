#!/bin/env ruby
# encoding: utf-8
#call_hook(:controller_issues_edit_before_save, { :params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal})
module Activity
  class ControllerIssuesEditBeforeSaveHook < Redmine::Hook::ViewListener
    def controller_issues_edit_before_save(context={})
      # Если получится, то вставить обработчик флеш-сообщений
    end
  end
end