import Route from "@ember/routing/route";

export default Route.extend({
  templateName: "user/billing/authorizations",

  model() {
    return this.modelFor('user');
  }
});
