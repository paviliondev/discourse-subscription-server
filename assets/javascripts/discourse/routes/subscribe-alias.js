import Route from "@ember/routing/route";

export default Route.extend({
  afterModel() {
    return this.replaceWith("subscribe");
  }
});
