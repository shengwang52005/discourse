import Component from "@glimmer/component";
import DMenu from "float-kit/components/d-menu";
import PeriodChooser from "select-kit/components/period-chooser";

export default class CustomPeriodChooser extends Component {
  <template>
    <DMenu>
      <:trigger>
        {{@period}}
      </:trigger>
      <:content>
        <div class="custom-period-chooser-content">
          <PeriodChooser
            @period={{@period}}
            @action={{@action}}
            @content={{@content}}
            @fullDay={{false}}
          />
        </div>
      </:content>
    </DMenu>
  </template>
}
