# frozen_string_literal: true
module DiscourseSubscriptionsCouponsControllerExtension
  def create
    params.require([:promo, :discount_type, :discount, :active, :applies_to_products])
    begin
      coupon_params = {
        duration: 'forever',
        max_redemptions: params[:max_redemptions] || 1,
        applies_to: {
          products: params[:applies_to_products]
        }
      }

      case params[:discount_type]
      when 'amount'
        coupon_params[:amount_off] = params[:discount].to_i * 100
        coupon_params[:currency] = SiteSetting.discourse_subscriptions_currency
      when 'percent'
        coupon_params[:percent_off] = params[:discount]
      end

      coupon = ::Stripe::Coupon.create(coupon_params)
      promo_code = ::Stripe::PromotionCode.create({ coupon: coupon[:id], code: params[:promo] }) if coupon.present?

      render_json_dump promo_code
    rescue ::Stripe::InvalidRequestError => e
      render_json_error e.message
    end
  end
end
