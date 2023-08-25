import { inject as service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { TrackedArray } from "@ember-compat/tracked-built-ins";
import ChatPaneBaseSubscriptionsManager from "./chat-pane-base-subscriptions-manager";
import ChatThreadPreview from "../models/chat-thread-preview";
import ChatNotice from "../models/chat-notice";

export default class ChatChannelPaneSubscriptionsManager extends ChatPaneBaseSubscriptionsManager {
  @service chat;
  @service currentUser;

  @tracked notices = new TrackedArray();

  get messageBusChannel() {
    return `/chat/${this.model.id}`;
  }

  get messageBusLastId() {
    return this.model.channelMessageBusLastId;
  }

  handleSentMessage() {
    return;
  }

  handleNotice(data) {
    this.notices.pushObject(ChatNotice.create(data));
  }

  clearNotice(notice) {
    this.notices.removeObject(notice);
  }

  handleThreadOriginalMessageUpdate(data) {
    const message = this.messagesManager.findMessage(data.original_message_id);
    if (message?.thread) {
      message.thread.preview = ChatThreadPreview.create(data.preview);
    }
  }

  _afterDeleteMessage(targetMsg, data) {
    if (this.model.currentUserMembership.lastReadMessageId === targetMsg.id) {
      this.model.currentUserMembership.lastReadMessageId =
        data.latest_not_deleted_message_id;
    }
  }
}
