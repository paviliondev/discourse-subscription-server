# frozen_string_literal: true

module SubscriptionServer
  class UserResource < ActiveRecord::Base

    belongs_to :user

    def ready?
      iam_user_name.present? && iam_access_key_id.present? && iam_secret_access_key.present?
    end

    def create_iam_user(resource_name)
      key = aws.create_user(
        user_name: self.user.username,
        group_name: self.class.resource_groups[resource_name]
      )
      if key
        self.update(
          iam_user_name: key[:user_name],
          iam_access_key_id: key[:access_key_id],
          iam_secret_access_key: key[:secret_access_key],
          iam_key_updated_at: Time.now
        )
      end
    end

    def rotate_iam_key
      return unless self.iam_user_name

      key = aws.rotate_key(user_name: self.iam_user_name)
      if key
        self.update(
          iam_access_key_id: key[:access_key_id],
          iam_secret_access_key: key[:secret_access_key],
          iam_key_updated_at: Time.now
        )
      end
    end

    def expire_iam_keys!
      return unless self.iam_user_name

      aws.expire_keys(user_name: self.iam_user_name)
    end

    def aws
      @aws ||= SubscriptionServer::AWS.new
    end

    def self.resource_groups
      @resource_groups ||= {
        'discourse-events': 'discourse_events'
      }.as_json
    end

    def self.resource_supported?(resource_name)
      resource_groups[resource_name].present?
    end

    def self.list(user_id, subscriptions)
      result = []

      subscriptions.each do |subscription|
        resource_name = subscription.resource
        next unless resource_supported?(resource_name)

        user_resource = self.find_or_create_by(
          user_id: user_id,
          resource_name: resource_name
        )

        if !user_resource.iam_user_name
          user_resource.create_iam_user(resource_name)
        elsif !user_resource.iam_access_key_id
          user_resource.rotate_iam_key
        end

        if user_resource.iam_key_updated_at > 1.week.ago
          user_resource.rotate_iam_key
        end

        if user_resource.ready?
          result << user_resource
        end
      end

      result
    end
  end
end

# == Schema Information
#
# Table name: subscription_server_user_resources
#
#  id                    :bigint           not null, primary key
#  user_id               :bigint           not null
#  resource_name         :string           not null
#  iam_user_name         :string
#  iam_access_key_id     :string
#  iam_secret_access_key :string
#  iam_key_updated_at    :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  idx_subscription_server_user_resources               (user_id,resource_name) UNIQUE
#  index_subscription_server_user_resources_on_user_id  (user_id)
#