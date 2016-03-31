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
  end

end
