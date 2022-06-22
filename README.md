# discourse-subscription-server

The Discourse Subscription Server Plugin works alongside the [Discourse Subscription Client Plugin](https://github.com/paviliondev/discourse-subscription-client) to allow for subscriptions involving Discourse. The primary use case is to provide subscriptions for Discourse plugins.

> Want to just use a subscription offered by a plugin you're using? Please see the [Discourse Subscription Client Plugin](https://github.com/paviliondev/discourse-subscription-client).

> Want to just use the Subscription Server Plugin to offer a plugin subscription? Please read [Add Subscriptions to your Discourse plugin](https://coop.pavilion.tech/t/add-subscriptions-to-your-discourse-plugin/542) for a step by step guide.

This readme describes the Subscription Server Plugin for reference purposes. It may be useful for plugin providers looking to understand the server in more depth or if you're creating your own subscription client.

If you just want to add a subscription to your plugin, [please read this instead](https://coop.pavilion.tech/t/add-subscriptions-to-your-discourse-plugin/542).

## Overview

The server plugin is run by the provider of a subscription. It's acts as a layer on top of a subscription payment provider, such as the [Discourse Subscriptions Plugin](https://meta.discourse.org/t/discourse-subscriptions/140818), and provides endpoints for clients to retrieve subscriptions associated with users and messages associated with subscriptions.

### Payment providers

Currently the plugin only supports Stripe via the [Discourse Subscriptions Plugin](https://meta.discourse.org/t/discourse-subscriptions/140818). Other payment providers can be added, including other implementations of Stripe. To add another provider you need to extend the [Provider](https://github.com/paviliondev/discourse-subscription-server/blob/main/lib/subscription_server/provider.rb) class, [overriding the methods as described in the notes in that class](https://github.com/paviliondev/discourse-subscription-server/blob/main/lib/subscription_server/provider.rb).

### Subscriptions

A client can list a user's subscriptions on the server by sending a GET request to ``/subscription-server/user-subscriptions`` with a user api key issued with the `discourse-subscription-server:user_subscription` scope in the ``User-Api-Key`` header.

If you're implementing your own subscription client (other than the Subscription Client Plugin) please read the [User API Key Specification](https://meta.discourse.org/t/user-api-keys-specification/48536) to understand how user api keys are being used here.

Note that the Server plugin creates an exception to the ``allowed user api auth redirects`` site setting, allowing the user to be redirected to any url if the only scope requested is the `discourse-subscription-server:user_subscription` scope. This allows a key to be issued to an arbitrary client. The `discourse-subscription-server:user_subscription` scope cannot be requested along with other scopes and can only be used to list a user's subscriptions.

### Messages

The Subscription server provides a model and a polling endpoint for messages to subscription clients.

#### Model

`title`: Title of the message
`message`: Body of the message
`type`: 0 (informational) or 1 (warning)
`resource`: name of the resource the message is about, e.g. ``discourse-custom-wizard``
`created_at`: time the message was created
`expired_at`: time the message expired

#### Endpoint

Any GET request to ``/subscription-server/messages`` will return a full list of all messages on the server, including expired messages. The subscription client should determine how to handle message types and expiry.

### To do

1. Add an admin interface for messages
2. Add per-client limits, i.e. limit the number of instances a forum admin can use your subscription on
