import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action, computed } from "@ember/object";
import { empty } from "@ember/object/computed";
import { inject as service } from "@ember/service";
import { Promise } from "rsvp";
import ChangeTags from "discourse/components/bulk-actions/change-tags";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import RadioButton from "discourse/components/radio-button";
import { topicLevels } from "discourse/lib/notification-levels";
import Topic from "discourse/models/topic";
import htmlSafe from "discourse-common/helpers/html-safe";
import i18n from "discourse-common/helpers/i18n";
import CategoryChooser from "select-kit/components/category-chooser";
import TagChooser from "select-kit/components/tag-chooser";

export default class BulkTopicActions extends Component {
  @service router;
  @tracked activeComponent = null;
  @tracked tags = [];

  categoryId = 0;
notificationLevelId = null;
@empty("notificationLevelId") disabled;
constructor() {
    super(...arguments);

    if (this.args.model.initialAction === "set-component") {
      this.setComponent(ChangeTags);
    }
  }

  async perform(operation) {
    this.loading = true;

    if (this.args.model.bulkSelectHelper.selected.length > 20) {
      this.showProgress = true;
    }

    try {
      return this._processChunks(operation);
    } catch {
      this.dialog.alert(i18n.t("generic_error"));
    } finally {
      this.loading = false;
      this.processedTopicCount = 0;
      this.showProgress = false;
    }
  }

  _generateTopicChunks(allTopics) {
    let startIndex = 0;
    const chunkSize = 30;
    const chunks = [];

    while (startIndex < allTopics.length) {
      chunks.push(allTopics.slice(startIndex, startIndex + chunkSize));
      startIndex += chunkSize;
    }

    return chunks;
  }

  _processChunks(operation) {
    const allTopics = this.args.model.bulkSelectHelper.selected;
    const topicChunks = this._generateTopicChunks(allTopics);
    const topicIds = [];
    const options = {};

    if (this.args.model.allowSilent === true) {
      options.silent = true;
    }

    const tasks = topicChunks.map((topics) => async () => {
      const result = await Topic.bulkOperation(topics, operation, options);
      this.processedTopicCount += topics.length;
      return result;
    });

    return new Promise((resolve, reject) => {
      const resolveNextTask = async () => {
        if (tasks.length === 0) {
          const topics = topicIds.map((id) => allTopics.findBy("id", id));
          return resolve(topics);
        }

        const task = tasks.shift();

        try {
          const result = await task();
          if (result?.topic_ids) {
            topicIds.push(...result.topic_ids);
          }
          resolveNextTask();
        } catch {
          reject();
        }
      };

      resolveNextTask();
    });
  }

  @action
  setComponent(component) {
    this.activeComponent = component;
  }

  @action
  performAction() {
    switch (this.args.model.action) {
      case "close":
        this.forEachPerformed({ type: "close" }, (t) => t.set("closed", true));
        break;
      case "archive":
        this.forEachPerformed({ type: "archive" }, (t) =>
          t.set("archived", true)
        );
        break;
      case "unlist":
        this.forEachPerformed({ type: "unlist" }, (t) =>
          t.set("unlisted", true)
        );
        break;
      case "relist":
        this.forEachPerformed({ type: "relist" }, (t) =>
          t.set("unlisted", false)
        );
        break;
      case "append-tags":
        this.performAndRefresh({ type: "append_tags", tags: this.tags });
        break;
      case "replace-tags":
        this.performAndRefresh({ type: "change_tags", tags: this.tags });
        break;
      case "remove-tags":
        this.performAndRefresh({ type: "remove_tags" });
        break;
      case "delete":
        this.performAndRefresh({ type: "delete" });
        break;
      case "reset-bump-dates":
        this.performAndRefresh({ type: "reset_bump_dates" });
        break;
      case "defer":
        this.performAndRefresh({ type: "destroy_post_timing" });
        break;
      case "update-notifications":
        this.performAndRefresh({
          type: "change_notification_level",
          notification_level_id: this.notificationLevelId,
        });
        break;
      case "update-category":
        this.forEachPerformed(
          {
            type: "change_category",
            category_id: this.categoryId,
          },
          (t) => t.set("category_id", this.categoryId)
        );
        break;
    }
  }

  @action
  async forEachPerformed(operation, cb) {
    const topics = await this.perform(operation);

    if (topics) {
      topics.forEach(cb);
      this.args.model.refreshClosure?.();
      this.args.closeModal();
      this.args.model.bulkSelectHelper.toggleBulkSelect();
    }
  }

  @action
  async performAndRefresh(operation) {
    await this.perform(operation);

    this.args.model.refreshClosure?.();
    this.args.closeModal();
    this.args.model.bulkSelectHelper.toggleBulkSelect();
  }

  @computed("action")
  get isTagAction() {
    return (
      this.args.model.action === "append-tags" ||
      this.args.model.action === "replace-tags"
    );
  }

  @computed("action")
  get isNotificationAction() {
    return this.args.model.action === "update-notifications";
  }

  @computed("action")
  get isCategoryAction() {
    return this.args.model.action === "update-category";
  }

  get notificationLevels() {
    return topicLevels.map((level) => ({
      id: level.id.toString(),
      name: i18n.t(`topic.notifications.${level.key}.title`),
      description: i18n.t(`topic.notifications.${level.key}.description`),
    }));
  }

  <template>
    <DModal
      @title={{@model.title}}
      @closeModal={{@closeModal}}
      class="topic-bulk-actions-modal -large"
    >
      <:body>
        <div>
          {{htmlSafe
            (i18n
              "topics.bulk.selected"
              count=@model.bulkSelectHelper.selected.length
            )
          }}
        </div>

        {{#if this.isCategoryAction}}
          <p>
            <CategoryChooser @value={{this.categoryId}} />
          </p>
        {{/if}}

        {{#if this.isNotificationAction}}
          <div class="bulk-notification-list">
            {{#each this.notificationLevels as |level|}}
              <div class="controls">
                <label class="radio notification-level-radio checkbox-label">
                  <RadioButton
                    @value={{level.id}}
                    @name="notification_level"
                    @selection={{this.notificationLevelId}}
                  />
                  <strong>{{level.name}}</strong>
                  <div class="description">{{htmlSafe level.description}}</div>
                </label>
              </div>
            {{/each}}
          </div>
        {{/if}}

        {{#if this.isTagAction}}
          <p><TagChooser @tags={{this.tags}} @categoryId={{@categoryId}} /></p>
        {{/if}}
      </:body>

      <:footer>
        {{#if @model.allowSilent}}
          <div class="topic-bulk-actions-options">
            <label
              for="topic-bulk-action-options__silent"
              class="checkbox-label"
            >
              <input
                class=""
                id="topic-bulk-action-options__silent"
                type="checkbox"
              />{{i18n "topics.bulk.silent"}}</label>
          </div>
        {{/if}}
        <DButton
          @action={{this.performAction}}
          @icon="check"
          @label="topics.bulk.confirm"
          id="bulk-topics-confirm"
          class="btn-primary"
        />
      </:footer>

    </DModal>
  </template>
}
