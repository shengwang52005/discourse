# frozen_string_literal: true

class AddTypeAndTargetIdToChatMentions < ActiveRecord::Migration[7.0]
  def up
    change_column :chat_mentions, :user_id, :integer, null: true
    add_column :chat_mentions, :type, :string, null: true
    add_column :chat_mentions, :target_id, :integer, null: true

    DB.exec <<~SQL
      UPDATE chat_mentions
      SET type = 'Chat::UserMention', target_id = user_id;
    SQL

    # fixme andrei add indexes
    # fixme andrei take care of old indexes
    # fixme andrei make the type column not nullable
  end

  def down
    change_column :chat_mentions, :user_id, :integer, null: false
    remove_column :chat_mentions, :type
    remove_column :chat_mentions, :target_id
  end
end
