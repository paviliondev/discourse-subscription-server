# frozen_string_literal: true
class CreateSubscriptionServerUserResources < ActiveRecord::Migration[7.1]
  def change
    create_table :subscription_server_user_resources do |t|
      t.references :user, null: false
      t.string :resource_name, null: false
      t.string :iam_user_name
      t.string :iam_access_key_id
      t.string :iam_secret_access_key
      t.string :iam_key_updated_at

      t.timestamps
    end

    add_index :subscription_server_user_resources,
              %i[user_id resource_name],
              unique: true,
              name: :idx_subscription_server_user_resources
  end
end
