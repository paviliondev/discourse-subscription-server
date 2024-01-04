import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";

export default Component.extend({
  classNameBindings: [":subscriptions-banner", "showBanner:visible"],

  @discourseComputed("currentPath", "text")
  showBanner(currentPath, text) {
    return currentPath.includes('subscribe') && text && text.length > 2;
  },

  @discourseComputed()
  text() {
    return this.siteSettings.custom_wizard_subscription_banner;
  }
});
