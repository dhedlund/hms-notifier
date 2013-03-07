require 'test_helper'

class NotificationObserverTest < ActiveSupport::TestCase
  test "should not create a new notification update if nothing has changed" do
    notification = FactoryGirl.create(:notification)
    assert_no_difference('NotificationUpdate.count') { notification.save! }
    assert_no_difference('NotificationUpdate.count') { notification.enrollment.save! }
  end

  #----------------------------------------------------------------------------#
  # changes to notification:
  #-------------------------
  test "should not create a notification update on enrollment create" do
    enrollment = FactoryGirl.build(:enrollment)
    assert_no_difference('NotificationUpdate.count') { enrollment.save! }
  end

  test "should create a notification update on notification update" do
    notification = FactoryGirl.create(:notification)
    notification.delivery_date += 1
    assert_difference('NotificationUpdate.count') { notification.save! }
  end

  test "should only create notification updates for active notifications" do
    notification = FactoryGirl.create(:notification)
    notification.update_attributes(:status => Notification::PERM_FAIL)
    notification.delivery_date += 1
    assert_no_difference('NotificationUpdate.count') { notification.save! }
  end

  test "notification changes should propagate into new notification update" do
    n = FactoryGirl.create(:notification)
    n.delivery_date += 1
    n.save!
    assert_equal n.delivery_date, n.updates.last.delivery_date
  end

  test "changing a notification to cancelled should create a CANCEL update" do
    notification = FactoryGirl.create(:notification)
    assert_difference('NotificationUpdate.count') do
      notification.update_attributes(:status => Notification::CANCELLED)
    end
    assert_equal NotificationUpdate::CANCEL, notification.updates.last.action
  end

  test "changing a notification after cancelled should not create an update" do
    notification = FactoryGirl.create(:notification)
    notification.update_attributes(:status => Notification::CANCELLED)

    assert_no_difference('NotificationUpdate.count') do
      notification.update_attributes(:status => Notification::PERM_FAIL)
    end

    notification.delivery_date += 1
    assert_no_difference('NotificationUpdate.count') { notification.save! }
  end

  #----------------------------------------------------------------------------#
  # changes to enrollment:
  #-----------------------
  test "should create a notification update on notification create" do
    notification = FactoryGirl.build(:notification)
    assert_difference('NotificationUpdate.count') { notification.save! }
  end

  test "should create not. update on enrollment update (if notifications)" do
    enrollment = FactoryGirl.create(:enrollment, :delivery_method => 'SMS')
    message = FactoryGirl.create(:message, :message_stream => enrollment.message_stream)
    notification = enrollment.notifications.create(:message => message)
    enrollment.delivery_method = 'IVR'
    assert_difference('NotificationUpdate.count') { enrollment.save! }
  end

  test "should create not. update for each notification on enrollment update" do
    enrollment = FactoryGirl.create(:enrollment, :delivery_method => 'SMS')
    3.times do
      m = FactoryGirl.create(:message, :message_stream => enrollment.message_stream)
      enrollment.notifications.create(:message => m)
    end
    enrollment.delivery_method = 'IVR'
    assert_difference('NotificationUpdate.count', 3) { enrollment.save! }
  end

  test "shouldn't create not. update on enrollment update (no notifications)" do
    enrollment = FactoryGirl.create(:enrollment, :delivery_method => 'SMS')
    enrollment.delivery_method = 'IVR'
    assert_no_difference('NotificationUpdate.count') { enrollment.save! }
  end

  test "enrollment changes should propagate into notification updates" do
    enrollment = FactoryGirl.create(:enrollment, :preferred_time => nil)
    3.times do
      m = FactoryGirl.create(:message, :message_stream => enrollment.message_stream)
      enrollment.notifications.create(:message => m)
    end
    enrollment.delivery_method = 'IVR'
    enrollment.save!

    updates = enrollment.notifications.map { |n| n.updates.last }
    assert updates.all? { |v| v.delivery_method == 'IVR' }
  end

  test "enrollment updates should only update active notifications" do
    enrollment = FactoryGirl.create(:enrollment, :preferred_time => nil)
    notifications = 3.times.map do
      m = FactoryGirl.create(:message, :message_stream => enrollment.message_stream)
      n = enrollment.notifications.create(:message => m)
      n.update_attributes(:status => Notification::PERM_FAIL)
    end

    enrollment.delivery_method = 'IVR'
    assert_no_difference('NotificationUpdate.count') { enrollment.save! }
  end

end
