module DiscourseSubscriptionsProductsControllerExtension
  def show
    begin
      product = ::Stripe::Product.retrieve(params[:id])

      if product[:metadata][:hidden].present?
        product[:metadata][:hidden] = ActiveRecord::Type::Boolean.new.cast(product[:metadata][:hidden])
      end

      render_json_dump product

    rescue ::Stripe::InvalidRequestError => e
      render_json_error e.message
    end
  end

  private def product_params
    params.permit!

    {
      name: params[:name],
      active: params[:active],
      statement_descriptor: params[:statement_descriptor],
      metadata: {
        description: params.dig(:metadata, :description),
        repurchaseable: params.dig(:metadata, :repurchaseable),
        hidden: params.dig(:metadata, :hidden)
      }
    }
  end
end