require 'controller_issues_edit_before_save_hook'
require 'controller_timelog_edit_before_save_hook'

Redmine::Plugin.register :activity do
  name 'Activity plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  settings :default => {'empty' => true}, :partial => 'settings/activity'

  ActionDispatch::Callbacks.to_prepare do
    require_dependency 'issue_status_patch'
    require_dependency 'time_entry_patch'
  end

  #call_hook(:controller_issues_edit_before_save, { :params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal})
  #call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })
end
