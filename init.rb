PLUGIN_NAME = 'efforts'

Redmine::Plugin.register :efforts do
  name 'Redmine efforts control plugin'
  author 'DigitalWand'
  description 'This plugin automatically sets activity type of an time entity by issue status. Also it prevents to spent more time, then estimated for issue.'
  version '0.1'
  url 'https://github.com/DigitalWand/efforts'
  author_url 'http://digitalwand.ru'

  settings :default => {max_ratio: 1, 'empty' => true}, :partial => 'settings/efforts'

  ActionDispatch::Callbacks.to_prepare do
    require_dependency 'issue_status_patch'
    require_dependency 'time_entry_patch'
    require_dependency 'issue_patch'
  end

  #call_hook(:controller_issues_edit_before_save, { :params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal})
  #call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })
end
