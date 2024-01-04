module DiscourseSubscriptionsSubscribeControllerExtension
  private def serialize_product(product)
    {
      id: product[:id],
      name: product[:name],
      description: PrettyText.cook(product[:metadata][:description]),
      subscribed: current_user_products.include?(product[:id]),
      repurchaseable: product[:metadata][:repurchaseable],
      hidden: ActiveRecord::Type::Boolean.new.cast(product[:metadata][:hidden])
    }
  end

  private def serialize_plans(plans)
    plans[:data].reduce([]) do |result, p|
      plan = p.to_h
      if plan[:nickname] != "hidden"
        result << plan.slice(:id, :unit_amount, :currency, :type, :recurring, :nickname)
      end
      result
    end.sort_by { |plan| plan[:amount] }
  end
end