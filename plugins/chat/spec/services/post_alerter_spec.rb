# frozen_string_literal: true

RSpec.describe PostAlerter do
  fab!(:topic) { Fabricate(:topic) }
  fab!(:user) { Fabricate(:user) }

  def create_post_with_alerts(args = {})
    post = Fabricate(:post, args)
    PostAlerter.post_created(post)
  end

  context "with @mentions" do
    before do
      Site.markdown_additional_options["chat"] = {
        limited_pretty_text_features: Chat::Message::MARKDOWN_FEATURES,
        limited_pretty_text_markdown_rules: Chat::Message::MARKDOWN_IT_RULES,
      }
      Jobs.run_immediately!
    end

    it "doesn't notify when a chat message with a mention was quoted in a post" do
      another_user = Fabricate(:user)
      raw =
        "<p>
           [chat quote='admin;3023;2023-11-02T19:42:48Z' channel='Test channel' channelId='3']
             <br>
             Hey <a class='mention' href='/u/#{another_user.username}'>@#{another_user.username}</a>
         </p>"

      expect { create_post_with_alerts(user: user, raw: raw, topic: topic) }.not_to change(
        another_user.notifications,
        :count,
      )
    end
  end
end
