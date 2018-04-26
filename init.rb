PLUGIN_NAME = 'efforts'
SETTINGS_NAME = "plugin_#{PLUGIN_NAME}".to_sym
RATIO_TEST = 'max_ratio_test'
RATIO_TEST_ID = 'ratio_test_id'
RATIO_CONTROL = 'max_ratio_control'
RATIO_CONTROL_ID = 'ratio_control_id1'

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
      RATIO_TEST => 0.2,
      RATIO_TEST_ID => IssueCustomField.find_by_name('Оценка тестирования').try(:id),
      RATIO_CONTROL => 0.1,
      RATIO_CONTROL_ID => IssueCustomField.find_by_name('Оценка руководства').try(:id),
  }

  ActionDispatch::Callbacks.to_prepare do
    require_dependency 'efforts_issue_status_patch'
    require_dependency 'time_entry_patch'
    require_dependency 'issue_patch'
    require_dependency 'view_hooks'
  end

  require File.dirname(__FILE__) + '/app/helpers/efforts_helper'
  ActionView::Base.send :include, EffortsHelper
end
