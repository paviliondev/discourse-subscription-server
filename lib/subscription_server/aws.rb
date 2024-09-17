# frozen_string_literal: true
module SubscriptionServer
  class AWS
    KEY_QUOTA = 2

    class SettingMissing < StandardError
    end

    def initialize(options = {})
      @options = default_options.merge(options)
    end

    def create_user(user_name: nil, group_name: nil)
      return unless user_name && group_name

      user_response = iam_create_user(user_name: user_name)
      return false unless user_response

      group_response = iam_add_to_group(user_name: user_name, group_name: group_name)
      return false unless group_response

      key = iam_create_key(user_name: user_name)
      return false unless key

      key
    end

    def rotate_key(user_name: nil)
      return unless user_name

      key_limit = KEY_QUOTA - 1
      key_count = 0

      keys = iam_list_keys(user_name: user_name)
      if keys.present?
        keys.each do |key|
          if key_count >= key_limit
            iam_delete_key(user_name: user_name, key_id: key[:access_key_id])
            next
          end
          key_count += 1

          iam_update_key(user_name: user_name, key_id: key[:access_key_id], status: "Inactive")
        end
      end

      new_key = iam_create_key(user_name: user_name)
      return false unless new_key

      keys = iam_list_keys(user_name: user_name)
      if keys.present?
        keys.each do |key|
          next if key[:access_key_id] == new_key[:access_key_id]
          iam_update_key(user_name: user_name, key_id: key[:access_key_id], status: "Inactive")
        end
      end

      new_key
    end

    def expire_keys(user_name: nil)
      keys = iam_list_keys(user_name: user_name)
      if keys.present?
        keys.each do |key|
          iam_update_key(user_name: user_name, key_id: key[:access_key_id], status: "Inactive")
        end
      end
    end

    def destroy_user(user_name: nil)
      return unless user_name

      groups = iam_list_groups(user_name: user_name)
      if groups.present?
        groups.each do |group|
          iam_remove_from_group(user_name: user_name, group_name: group[:group_name])
        end
      end

      keys = iam_list_keys(user_name: user_name)
      if keys.present?
        keys.each do |key|
          iam_delete_key(user_name: user_name, key_id: key[:access_key_id])
        end
      end

      iam_delete_user(user_name: user_name)

      true
    end

    protected

    def iam_create_user(user_name: nil, group_name: nil)
      response = iam_client.create_user(user_name: user_name)
      return false unless response&.respond_to?(:user)

      iam_client.wait_until(:user_exists, user_name: user_name)
      logger.info("User '#{user_name}' created successfully.")

      true
    rescue Aws::IAM::Errors::EntityAlreadyExists
      logger.error("Error creating user '#{user_name}': user already exists.")
      false
    rescue Aws::IAM::Errors::ServiceError => e
      logger.error("Error creating user '#{user_name}': #{e.message}")
      false
    end

    def iam_add_to_group(user_name: nil, group_name: nil)
      iam_client.add_user_to_group(group_name: group_name, user_name: user_name)
      logger.info("User '#{user_name}' added to #{group_name}.")
      true
    rescue Aws::IAM::Errors::ServiceError => e
      logger.error("Error adding '#{user_name}' to #{group_name}: #{e.message}")
      false
    end

    def iam_remove_from_group(user_name: nil, group_name: nil)
      iam_client.remove_user_from_group(group_name: group_name, user_name: user_name)
      logger.info("User '#{user_name}' removed from #{group_name}.")
      true
    rescue Aws::IAM::Errors::ServiceError => e
      logger.error("Error removing '#{user_name}' from #{group_name}: #{e.message}")
      false
    end

    def iam_list_groups(user_name: nil, group_name: nil)
      response = iam_client.list_groups_for_user(
        user_name: user_name,
        group_name: group_name
      )
      response.to_h[:groups]
    rescue Aws::IAM::Errors::ServiceError => e
      logger.error("Error listing groups of '#{user_name}': #{e.message}")
      false
    end

    def iam_delete_user(user_name: nil)
      iam_client.delete_user(user_name: user_name)
      true
    rescue Aws::IAM::Errors::ServiceError => e
      logger.error("Error deleting user '#{user_name}': #{e.message}")
      false
    end

    def iam_create_key(user_name: nil)
      response = iam_client.create_access_key(user_name: user_name)
      return false unless response&.respond_to?(:to_h)

      response.to_h[:access_key]
    rescue Aws::IAM::Errors::ServiceError => e
      logger.error("Error creating key for '#{user_name}': #{e.message}")
      false
    end

    def iam_update_key(user_name: nil, key_id: nil, status: nil)
      iam_client.update_access_key(user_name: user_name, access_key_id: key_id, status: status)

      keys = iam_list_keys(user_name: user_name)
      return false unless keys.present?

      keys.any? { |key| key[:access_key_id] == key_id && key[:status] == status }
    rescue Aws::IAM::Errors::ServiceError => e
      logger.error("Error updating key (#{key_id}) of '#{user_name}': #{e.message}")
      false
    end

    def iam_delete_key(user_name: nil, key_id: nil)
      iam_client.delete_access_key(user_name: user_name, access_key_id: key_id)
      true
    rescue Aws::IAM::Errors::ServiceError => e
      logger.error("Error deleting access key (#{key_id}) of '#{user_name}': #{e.message}")
      false
    end

    def iam_list_keys(user_name: nil)
      response = iam_client.list_access_keys(user_name: user_name)
      response.to_h[:access_key_metadata]
    rescue Aws::IAM::Errors::ServiceError => e
      logger.error("Error listing access keys of '#{user_name}': #{e.message}")
      false
    end

    def logger
      @logger ||= Rails.logger
    end

    def iam_client
      @iam_client ||= init_iam_client
    end

    def init_iam_client
      options = @options
      options = options.merge(stub_responses: true) if Rails.env.test?
      Aws::IAM::Client.new(options)
    end

    def default_options
      check_missing_options
      {
        access_key_id: SiteSetting.subscription_server_iam_access_key,
        secret_access_key: SiteSetting.subscription_server_iam_secret_access_key
      }
    end

    def check_missing_options
      raise SettingMissing.new("iam_access_key_id") if SiteSetting.subscription_server_iam_access_key.blank?
      raise SettingMissing.new("iam_secret_access_key") if SiteSetting.subscription_server_iam_secret_access_key.blank?
    end
  end
end
