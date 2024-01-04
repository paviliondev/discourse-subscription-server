import Component from "@glimmer/component";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import { tracked } from "@glimmer/tracking";

export default class SubscriptionDomain extends Component {
  @tracked removing;

  @action
  removeDomain() {
    this.removing = true;
    this.args.remove(this.args.domain)
      .finally(() => {
        if (this.isDestroying || this.isDestroyed) {
          return;
        }
        this.removing = false;
      })
  }

  <template>
    <span>{{@domain}}</span>
    <DButton
      @icon="minus"
      @class="remove-domain"
      @action={{this.removeDomain}}
      @title="discourse_subscriptions.user.authorizations.remove_domain.title"
      @disabled={{this.removing}}
      />
  </template>
}