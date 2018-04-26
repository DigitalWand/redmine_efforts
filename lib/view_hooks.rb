module RedmineEfforts
  class Hooks < Redmine::Hook::ViewListener
      render_on :view_issues_show_details_bottom, partial: 'hooks/rm_efforts_part_time'
  end
end
