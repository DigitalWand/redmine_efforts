class CreateEstimatedCustomField < ActiveRecord::Migration
  def change
    reversible do |change|
      change.up do
        cf = IssueCustomField.new
        cf.name = "Estimated hours internal"
        cf.field_format = 'float'
        cf.is_required = 't'
        cf.is_for_all = 't'
        cf.is_filter = 'f'
        cf.editable = 't'
        cf.visible = 't'
        cf.multiple = 'f'
        cf.save!
      end
    end
  end
end
