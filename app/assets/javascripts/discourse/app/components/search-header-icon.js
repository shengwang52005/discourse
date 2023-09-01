import Component from "@glimmer/component";
import { action } from "@ember/object";
import { next } from "@ember/runloop";

export default class SearchHeaderIcon extends Component {
  // constructor() {
  //   super(...arguments);
  //   next(() => document.addEventListener("click", this.clickOustide, true));
  // }
  // willDestroy() {
  //   document.removeEventListener("click", this.args.toggleSearchMenu, true);
  // }
  // @action
  // clickOustide(e) {
  //   console.log(e);
  //   document.querySelector(".header-dropdown-toggle.search-dropdown");
  //   // this.args.toggleSearchMenu
  // }
}
