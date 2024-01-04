import { withPluginApi } from "discourse/lib/plugin-api";
import discourseComputed from "discourse-common/utils/decorators";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";
import { customProducts, productOrder } from '../lib/products';

export default {
  name: 'subscription-servier-initializer',
  initialize() {
    withPluginApi('0.8.30', api => {
      api.modifyClass('component:payment-plan', {
        pluginId: 'discourse-subscription-server',
        classNameBindings: [':btn-pavilion-subscribe', 'selectedClass'],
        tagName: "div",

        click() {
          this.clickPlan(this.plan);
        }
      });

      api.modifyClass('route:admin-plugins-discourse-subscriptions-coupons', {
        pluginId: 'discourse-subscription-server',

        afterModel() {
          const AdminProduct = requirejs("discourse/plugins/discourse-subscriptions/discourse/models/admin-product").default;
          return AdminProduct.findAll().then(products => {
            this.set('products', products);
          });
        },

        setupController(controller, model) {
          controller.setProperties({
            model,
            products: this.products
          })
        }
      });

      api.modifyClass('controller:admin-plugins-discourse-subscriptions-coupons', {
        pluginId: 'discourse-subscription-server',

        actions: {
          createNewCoupon(params) {
            const data = {
              promo: params.promo,
              discount_type: params.discount_type,
              discount: params.discount,
              active: params.active,
              applies_to_products: params.applies_to_products
            };

            return ajax("/s/admin/coupons", {
              method: "post",
              data,
            })
            .then(() => {
              this.send("closeCreateForm");
              this.send("reloadModel");
            })
            .catch(popupAjaxError);
          }
        }
      });

      const couponController = api._lookupContainer('controller:admin-plugins-discourse-subscriptions-coupons');
      api.modifyClass('component:create-coupon-form', {
        pluginId: 'discourse-subscription-server',

        @discourseComputed
        products() {
          return couponController.get('products');
        },

        actions: {
          createNewCoupon() {
            const createParams = {
              promo: this.promoCode,
              discount_type: this.discountType,
              discount: this.discount,
              active: this.active,
              applies_to_products: [this.productId]
            };
            this.create(createParams);
          },
        },
      });

      api.modifyClass('route:subscribe-index', {
        pluginId: 'discourse-subscription-server',

        setupController(controller, model) {
          const stripeProducts = model;
          const Product = requirejs("discourse/plugins/discourse-subscriptions/discourse/models/product").default;
          const nonStripeProducts = customProducts().map((product) => Product.create(product));
          const products = stripeProducts
            .concat(nonStripeProducts)
            .filter(p => (!p.hidden))
            .sort(function(a,b) {
              return productOrder.indexOf(a.name) - productOrder.indexOf(b.name);
            });
          controller.set('model', products);
        }
      });
    })
  }
}
