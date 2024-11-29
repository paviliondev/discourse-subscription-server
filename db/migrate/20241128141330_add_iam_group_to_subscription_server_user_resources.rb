# frozen_string_literal: true
class AddIamGroupToSubscriptionServerUserResources < ActiveRecord::Migration[7.2]
  def change
    add_column :subscription_server_user_resources, :iam_group, :string
  end
end
