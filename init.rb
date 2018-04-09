PLUGIN_NAME = 'efforts'
SETTINGS_NAME = "plugin_#{PLUGIN_NAME}".to_sym

Redmine::Plugin.register PLUGIN_NAME.to_sym do
  name 'Redmine efforts control plugin'
  author 'DigitalWand'
  description 'This plugin automatically sets activity type of an time entity by issue status. Also it prevents to spent more time, then estimated for issue.'
  version '0.1'
  url 'https://github.com/DigitalWand/redmine_efforts'
  author_url 'http://digitalwand.ru'

  settings :partial => 'settings/efforts', :default => {
      max_ratio: 1,
      'empty' => true,
      roles: [3, 9],   # Для каких ролей присылаем уведомления 3-менеджер, 9-тимлид
      limit: 0,        # Допуск, по которому можно превышать(+) или не допускать превышения(-)
  }

  ActionDispatch::Callbacks.to_prepare do
    require_dependency 'efforts_issue_status_patch'
    require_dependency 'time_entry_patch'
    require_dependency 'issue_patch'
  end

  #call_hook(:controller_issues_edit_before_save, { :params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal})
  #call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })
end
