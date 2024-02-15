import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import TopicStatusIcons from "discourse/helpers/topic-status-icons";
import { escapeExpression } from "discourse/lib/utilities";
import icon from "discourse-common/helpers/d-icon";
import I18n from "discourse-i18n";

export default class Status extends Component {
  @service currentUser;

  get canAct() {
    return this.currentUser && !this.args.disableActions;
  }

  get topicStatuses() {
    let topicStatuses = [];
    TopicStatusIcons.render(this.args.topic, (name, key) => {
      const iconArgs = { class: key === "unpinned" ? "unpinned" : null };
      const statusIcon = { name, iconArgs };

      const attributes = {
        title: escapeExpression(I18n.t(`topic_statuses.${key}.help`)),
      };
      let klass = "topic-status";
      if (key === "unpinned" || key === "pinned") {
        klass += `.pin-toggle-button.${key}`;
      }
      topicStatuses.push({ attributes, klass, icon: statusIcon });
    });

    return topicStatuses;
  }

  @action
  togglePinnedForUser(e) {
    const parent = e.target.closest(".topic-statuses");
    if (parent?.querySelector(".pin-toggle-button")?.contains(e.target)) {
      this.args.topic.togglePinnedForUser();
    }
  }

  <template>
    {{! template-lint-disable no-invalid-interactive }}
    <span class="topic-statuses" {{on "click" this.togglePinnedForUser}}>
      {{#each this.topicStatuses as |status|}}
        {{#if this.canAct}}
          <a class="topic-status {{status.klass}}">
            {{icon status.icon.name class=status.icon.iconArgs.class}}
          </a>
        {{else}}
          <span class="topic-status {{status.klass}}">
            {{icon status.icon.name class=status.icon.iconArgs.class}}
          </span>
        {{/if}}
      {{/each}}
    </span>
  </template>
}
