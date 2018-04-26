class CreateMoreEstimatedCustomField < ActiveRecord::Migration
  def up
    data = {
      field_format: 'float',
      is_required: false,
      is_for_all: true,
      is_filter: false,
      editable: false,
      visible: false,
      multiple: false,
      searchable: false,
      default_value: 0,
      tracker_ids: Tracker.all.map(&:id), # Всем треккерам доступно
      role_ids: [3, 4, 6, 8, 9] # Плохо, надо связать с чем то реальным...
    }
    if IssueCustomField.find_by_name('Оценка тестирования').blank?
      IssueCustomField.create(data.merge({name: 'Оценка тестирования'}))
    end
    if IssueCustomField.find_by_name('Оценка руководства').blank?
      IssueCustomField.create(data.merge({name: 'Оценка руководства'}))
    end
    if TrackersStatusesActivities.where({tracker_id: 2, activity: 'руководство'}).blank?
      TrackersStatusesActivities.create({tracker_id: 2, activity: 'руководство'})
    end

  end

  def down
    IssueCustomField.find_by_name('Оценка тестирования').try(:delete)
    IssueCustomField.find_by_name('Оценка руководства').try(:delete)
    TrackersStatusesActivities.where({tracker_id: 2, activity: 'руководство'}).delete_all
  end
end
