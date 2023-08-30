import Component from "@glimmer/component";
import MentionWithoutMembership from "discourse/plugins/chat/discourse/components/chat/notices/mention_without_membership";

const COMPONENT_DICT = {
  mention_without_membership: MentionWithoutMembership,
};

export default class ChatNoticeContent extends Component {
  get contentComponent() {
    return COMPONENT_DICT[this.args.notice.type];
  }
}
