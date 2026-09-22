module Paddle
  class Notification < Object
    class << self
      def list(**params)
        response = Client.get_request("notifications", params: params)
        Collection.from_response(response, type: Notification)
      end

      def retrieve(id:)
        response = Client.get_request("notifications/#{id}")
        Notification.new(response.body["data"])
      end

      # Only delivered or failed notifications with an origin of "event" can be replayed.
      # Returns a Notification with the notification_id of the new notification.
      def replay(id:)
        response = Client.post_request("notifications/#{id}/replay")
        Notification.new(response.body["data"])
      end

      def logs(id:, **params)
        response = Client.get_request("notifications/#{id}/logs", params: params)
        Collection.from_response(response, type: NotificationLog)
      end
    end
  end
end
