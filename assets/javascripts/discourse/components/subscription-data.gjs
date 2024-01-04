import Component from "@glimmer/component";
import SubscriptionDomains from "./subscription-domains";

export default class SubscriptionDomain extends Component {
  <template>
    <tr class='subscription-data'>
      <td>{{@data.resource}}</td>
      <td>
        <ul>
          {{#each @data.products as |product|}}
            <li><span>{{product}}</span></li>
          {{/each}}
        </ul>
      </td>
      <td>
        <SubscriptionDomains @domains={{@data.domains}} />
      </td>
      <td>{{@data.domain_limit}}</td>
    </tr>
  </template>
}
