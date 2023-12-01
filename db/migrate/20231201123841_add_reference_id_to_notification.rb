# frozen_string_literal: true

class AddReferenceIdToNotification < ActiveRecord::Migration[7.0]
  def up
    add_column :notifications, :reference_id, :integer, null: true

    DB.exec <<~SQL
      UPDATE notifications n
      SET reference_id = m.id
      FROM chat_mentions m
      WHERE n.id = m.notification_id;
    SQL

    add_index :notifications, :reference_id
  end

  def down
    remove_index :notifications, :reference_id
    remove_column :notifications, :reference_id
  end
end
