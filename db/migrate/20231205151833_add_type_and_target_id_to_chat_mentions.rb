# frozen_string_literal: true

class AddTypeAndTargetIdToChatMentions < ActiveRecord::Migration[7.0]
  def up
    add_column :chat_mentions, :type, :integer, null: true
    add_column :chat_mentions, :target_id, :integer, null: true

    DB.exec <<~SQL
      UPDATE chat_mentions
      SET type = 1, target_id = user_id;
    SQL

    # fixme andrei add indexes
    # fixme andrei take care of old indexes
    # fixme andrei make type column not nullable
  end

  def down
    remove_column :chat_mentions, :type
    remove_column :chat_mentions, :target_id
  end
end
