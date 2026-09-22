require "test_helper"

class Notification < Minitest::Test
  def test_notification_list
    notifications = Paddle::Notification.list

    assert_equal Paddle::Collection, notifications.class
    assert_equal Paddle::Notification, notifications.data.first.class
    assert_equal "ntf_01h7e0s0xktjj1cjd955aah5v5", notifications.data.first.id
  end

  def test_notification_retrieve
    notification = Paddle::Notification.retrieve(id: "ntf_01h7e0s0xktjj1cjd955aah5v5")

    assert_equal Paddle::Notification, notification.class
    assert_equal "ntf_01h7e0s0xktjj1cjd955aah5v5", notification.id
    assert_equal "subscription.activated", notification.type
  end

  def test_notification_logs
    notification_logs = Paddle::Notification.logs(id: "ntf_01h7e0s0xktjj1cjd955aah5v5")

    assert_equal Paddle::Collection, notification_logs.class
    assert_equal Paddle::NotificationLog, notification_logs.data.first.class
    assert_equal 200, notification_logs.data.first.response_code
  end

  def test_notification_replay
    notification = Paddle::Notification.replay(id: "ntf_01h8bkrfe7w1vwf8xmytwn51e7")

    assert_equal Paddle::Notification, notification.class
    assert_equal "ntf_01h46h1s2zabpkdks7yt4vkgkc", notification.notification_id
  end
end
