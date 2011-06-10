require 'test_helper'

class NotificationUpdateTest < ActiveSupport::TestCase
  test "valid notification update should be valid" do
    assert Factory.build(:notification_update).valid?
  end

  test "should be invalid without a first_name" do
    update = Factory.build(:notification_update)
    update.first_name = nil
    assert update.invalid?
  end

  test "should be invalid without a phone_number" do
    update = Factory.build(:notification_update)
    update.phone_number = nil
    assert update.invalid?
  end

  test "should be invalid without a delivery_method" do
    update = Factory.build(:notification_update)
    update.delivery_method = nil
    assert update.invalid?
  end

  test "should be invalid without a message_path" do
    update = Factory.build(:notification_update)
    update.message_path = nil
    assert update.invalid?
  end

  test "should be invalid without a delivery_date" do
    update = Factory.build(:notification_update)
    update.delivery_date = nil
    assert update.invalid?
  end

  test "should be valid without a delivery_expires date" do
    update = Factory.build(:notification_update)
    update.delivery_expires = nil
    assert update.valid?
  end

  test "should be valid without an uploaded_at datetime" do
    update = Factory.build(:notification_update)
    update.uploaded_at = nil
    assert update.valid?
  end

  test "should be valid without a response_code" do
    update = Factory.build(:notification_update)
    update.response_code = nil
    assert update.valid?
  end

  #----------------------------------------------------------------------------#
  # action:
  #--------
  test "should be invalid without an action" do
    assert Factory.build(:notification_update, :action => nil).invalid?
  end

  test "an unknown action should be invalid" do
    assert Factory.build(:notification_update,
      :action => 'WREAK_HAVOC'
    ).invalid?
  end

  test "an action of 'CREATE' should be valid" do
    assert Factory.build(:notification_update,
      :action => NotificationUpdate::CREATE
    ).valid?
  end

  test "an action of 'UPDATE' should be valid" do
    assert Factory.build(:notification_update,
      :action => NotificationUpdate::UPDATE
    ).valid?
  end

  test "an action of 'DESTROY' should be valid" do
    assert Factory.build(:notification_update,
      :action => NotificationUpdate::CANCEL
    ).valid?
  end

  #----------------------------------------------------------------------------#
  # notification:
  #--------------
  test "should be invalid without a notification" do
    assert Factory.build(:notification_update, :notification => nil).invalid?
  end

  test "can access notification from notification update" do
    assert Factory.build(:notification_update).notification
  end

  test "assigning a notification should set first name" do
    notification = Factory.create(:notification)
    update = Factory.build(:notification_update, :notification => nil)
    update.notification = notification
    assert_not_nil update.first_name
  end

  test "assigning a notification should set phone_number" do
    notification = Factory.create(:notification)
    update = Factory.build(:notification_update, :notification => nil)
    update.notification = notification
    assert_not_nil update.phone_number
  end

  test "assigning a notification should set delivery_method" do
    notification = Factory.create(:notification)
    update = Factory.build(:notification_update, :notification => nil)
    update.notification = notification
    assert_not_nil update.delivery_method
  end

  test "assigning a notification should set message_path" do
    notification = Factory.create(:notification)
    update = Factory.build(:notification_update, :notification => nil)
    update.notification = notification
    assert_not_nil update.message_path
  end

  test "assigning a notification should set delivery_date" do
    notification = Factory.create(:notification)
    update = Factory.build(:notification_update, :notification => nil)
    update.notification = notification
    assert_not_nil update.delivery_date
  end

  test "assigning a notification should set preferred_time" do
    notification = Factory.create(:notification, :preferred_time => '10-19')
    update = Factory.build(:notification_update, :notification => nil)
    update.notification = notification
    assert_not_nil update.preferred_time
  end

end
