# frozen_string_literal: true

module ::Jobs
  class SubscriptionServerExpireStaleKeys < ::Jobs::Scheduled
    every 1.week

    def execute(args)
      SubscriptionServer::UserResource.all.each do |user_resource|
        if user_resource.ready? && user_resource.iam_key_updated_at > 3.weeks.ago
          user_resource.expire_iam_keys!
        end
      end
    end
  end
end
