import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import DButton from "discourse/components/d-button";
import and from "truth-helpers/helpers/and";
import not from "truth-helpers/helpers/not";

export default class AuthButtons extends Component {
  @service header;

  <template>
    <span class="header-buttons">
      {{#if (and @canSignUp (not this.header.topic))}}
        <DButton
          class="btn-primary btn-small sign-up-button"
          @action={{@showCreateAccount}}
          @label="sign_up"
        />
      {{/if}}

      <DButton
        class="btn-primary btn-small login-button"
        @action={{@showLogin}}
        @label="log_in"
        @icon="user"
      />
    </span>
  </template>
}
