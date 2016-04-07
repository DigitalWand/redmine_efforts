require 'controller_issues_edit_before_save_hook'
require 'controller_timelog_edit_before_save_hook'
PLUGIN_NAME = 'activity'

Redmine::Plugin.register :activity do
  name 'Redmine custom logtime plugin'
  author 'DigitalWand'
  description 'This is a plugin for Redmine'
  version '0.0.2'
  url 'https://github.com/DigitalWand/digitalwand.redmine_custom_logtime'
  author_url 'http://digitalwand.ru'

  settings :default => {max_ratio: 1, 'empty' => true}, :partial => 'settings/activity'

  ActionDispatch::Callbacks.to_prepare do
    require_dependency 'issue_status_patch'
    require_dependency 'time_entry_patch'
  end

  #call_hook(:controller_issues_edit_before_save, { :params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal})
  #call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })
end
