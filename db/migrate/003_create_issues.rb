class CreateIssues < ActiveRecord::Migration
  def change
    add_column :issues, :message_of_exceeding_estimate, :boolean
  rescue => e
    # Так как перенес из другого плагина, повторное поднятие миграции на той же базе приведет к ошибке
    puts "ERROR: #{e}"
  end
end
