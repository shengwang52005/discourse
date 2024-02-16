import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import getURL from "discourse-common/lib/get-url";
import not from "truth-helpers/helpers/not";
import or from "truth-helpers/helpers/or";
import MountWidget from "../mount-widget";
import Dropdown from "./dropdown";
import UserDropdown from "./user-dropdown";
import PanelWrapper from "./panel-wrapper";

let _extraHeaderIcons = [];
export function addToHeaderIcons(icon) {
  _extraHeaderIcons.push(icon);
}

export function clearExtraHeaderIcons() {
  _extraHeaderIcons = [];
}

export default class Icons extends Component {
  @service site;
  @service currentUser;
  @service header;
  @service search;

  _isStringType = (icon) => typeof icon === "string";

  <template>
    <ul class="icons d-header-icons">
      {{#each _extraHeaderIcons as |icon|}}
        {{#if (this._isStringType icon)}}
          <MountWidget @widget={{icon}} />
        {{else}}
          {{#with
            (component PanelWrapper panelElement=@panelElement)
            as |panelWrapper|
          }}
            <icon @panelWrapper={{panelWrapper}} />
          {{/with}}
        {{/if}}
      {{/each}}

      <Dropdown
        @title="search.title"
        @icon="search"
        @iconId={{@searchButtonId}}
        @onClick={{@toggleSearchMenu}}
        @active={{this.search.visible}}
        @href={{getURL "/search"}}
        @className="search-dropdown"
        @targetSelector=".search-menu-panel"
      />

      {{#if (or (not @sidebarEnabled) this.site.mobileView)}}
        <Dropdown
          @title="hamburger_menu"
          @icon="bars"
          @iconId="toggle-hamburger-menu"
          @active={{this.header.hamburgerVisible}}
          @onClick={{@toggleHamburger}}
          @href=""
          @className="hamburger-dropdown"
        />
      {{/if}}

      {{#if this.currentUser}}
        <UserDropdown
          @active={{this.header.userVisible}}
          @toggleUserMenu={{@toggleUserMenu}}
        />
      {{/if}}
    </ul>
  </template>
}
