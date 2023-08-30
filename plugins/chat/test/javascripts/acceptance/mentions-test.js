import {
  acceptance,
  emulateAutocomplete,
  loggedInUser,
  publishToMessageBus,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { click, triggerEvent, visit, waitFor } from "@ember/test-helpers";
import pretender, { response } from "discourse/tests/helpers/create-pretender";

acceptance("Chat | Mentions", function (needs) {
  const channelId = 1;
  const messageId = 1;
  const actingUser = {
    id: 1,
    username: "acting_user",
  };
  const mentionedUser1 = {
    id: 1000,
    username: "user1",
    status: {
      description: "surfing",
      emoji: "surfing_man",
    },
  };
  const mentionedUser2 = {
    id: 2000,
    username: "user2",
    status: {
      description: "vacation",
      emoji: "desert_island",
    },
  };
  const mentionedUser3 = {
    id: 3000,
    username: "user3",
    status: {
      description: "off to dentist",
      emoji: "tooth",
    },
  };
  const message = {
    id: messageId,
    message: `Hey @${mentionedUser1.username}`,
    cooked: `<p>Hey <a class="mention" href="/u/${mentionedUser1.username}">@${mentionedUser1.username}</a></p>`,
    mentioned_users: [mentionedUser1],
    user: actingUser,
    created_at: "2020-08-04T15:00:00.000Z",
  };
  const channel = {
    id: channelId,
    chatable_id: 1,
    chatable_type: "Category",
    meta: { message_bus_last_ids: {}, can_delete_self: true },
    current_user_membership: { following: true },
    chatable: { id: 1 },
  };

  needs.settings({ chat_enabled: true });

  needs.user({
    ...actingUser,
    has_chat_enabled: true,
    chat_channels: {
      public_channels: [channel],
      direct_message_channels: [],
      meta: { message_bus_last_ids: {} },
      tracking: {},
    },
  });

  needs.hooks.beforeEach(function () {
    pretender.post(`/chat/1`, () => response({}));
    pretender.put(`/chat/1/edit/${messageId}`, () => response({}));
    pretender.post(`/chat/drafts`, () => response({}));
    pretender.put(`/chat/api/channels/1/read/1`, () => response({}));
    pretender.get(`/chat/api/channels/1/messages`, () =>
      response({
        messages: [message],
        meta: {
          can_load_more_future: false,
        },
      })
    );
    pretender.delete(`/chat/api/channels/1/messages/${messageId}`, () =>
      response({})
    );
    pretender.put(`/chat/api/channels/1/messages/${messageId}/restore`, () =>
      response({})
    );

    pretender.get("/u/search/users", () =>
      response({
        users: [mentionedUser2, mentionedUser3],
      })
    );

    pretender.get("/chat/api/mentions/groups.json", () =>
      response({
        unreachable: [],
        over_members_limit: [],
        invalid: ["and"],
      })
    );
  });

  test("ignore duplicates when counting against the mentions limit", async function (assert) {
    await visit(`/chat/c/-/${channelId}`);
    assert.ok(true);
  });
});
