import Component from "@glimmer/component";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import { tracked } from "@glimmer/tracking";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";
import SubscriptionDomain from "./subscription-domain";

export default class SubscriptionDomains extends Component {
  @tracked domains;

  constructor() {
    super(...arguments);
    this.domains = this.args.domains;
  }

  @action
  removeDomain(domain) {
    return ajax('/subscription-server/user-authorizations', {
      type: 'DELETE',
      data: {
        domain
      }
    })
      .catch(popupAjaxError)
      .then(() => {
        this.domains = this.domains.filter((d) => (d !== domain));
      });
  }

  <template>
    <ul>
      {{#each this.domains as |domain|}}
        <li class="subscription-domain">
          <SubscriptionDomain @domain={{domain}} @remove={{this.removeDomain}} />
        </li>
      {{/each}}
    </ul>
  </template>
}