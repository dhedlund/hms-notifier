require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  setup do
    @notification = Factory.build(:notification)
  end

  test "valid notification should be valid" do
    assert Factory.build(:notification).valid?
  end

  test "should be invalid without a delivery_date" do
    assert Factory.build(:notification, :delivery_date => nil).invalid?
  end

  test "preferred_time is optional" do
    assert Factory.build(:notification, :preferred_time => nil).valid?
  end

  test "delivered_at is optional" do
    assert Factory.build(:notification, :delivered_at => nil).valid?
  end

  test "status is optional" do
    assert Factory.build(:notification, :status => nil).valid?
  end

  #----------------------------------------------------------------------------#
  # uuid:
  #------
  test "uuid is optional" do
    assert Factory.build(:notification, :uuid => nil).valid?
  end

  test "two notifications cannot share the same uuid" do
    Factory.create(:notification, :uuid => 'abc123')
    assert Factory.build(:notification, :uuid => 'abc123').invalid?
  end

  test "uuid is auto-generated on save if none specified" do
    notification = Factory.create(:notification, :uuid => nil)
    assert_not_nil notification.uuid
  end

  test "uuid autogenerator should generate unique uuids" do
    n1 = Factory.create(:notification, :uuid => nil)
    n2 = Factory.create(:notification, :uuid => nil)
    assert_not_equal n1.uuid, n2.uuid
  end

  test "should not change uuid on save if already specified" do
    notification = Factory.create(:notification, :uuid => 'abc123')
    notification.save!
    assert_equal 'abc123', notification.uuid
  end

  #----------------------------------------------------------------------------#
  # relationship w/ Enrollment:
  #----------------------------
  test "should be invalid without an enrollment_id" do
    assert Factory.build(:notification, :enrollment_id => nil).invalid?
  end

  test "can access enrollment from notification" do
    assert Factory.build(:notification).enrollment
  end

  #----------------------------------------------------------------------------#
  # relationship w/ Message:
  #-------------------------
  test "should be invalid without a message_id" do
    assert Factory.build(:notification, :message_id => nil).invalid?
  end

  test "can access message from notification" do
    assert Factory.build(:notification).message
  end

  test "same message cannot exist twice for a single enrollment" do
    stream = Factory.create(:message_stream)
    message = Factory.create(:message, :message_stream => stream)
    enrollment = Factory.create(:enrollment, :message_stream => stream)
    Factory.create(:notification, :enrollment => enrollment, :message => message)
    assert Factory.build(:notification, :enrollment => enrollment, :message => message).invalid?
  end

  #----------------------------------------------------------------------------#
  # relationship w/ NotificationUpdate:
  #------------------------------------
  test "can associate multiple updates with a notification" do
    notification = Factory.build(:notification)
    assert_difference('notification.updates.size', 2) do
      2.times { notification.updates << Factory.build(:notification_update) }
    end
  end

  #----------------------------------------------------------------------------#
  # relationship w/ NotificationResponse:
  #--------------------------------------
  test "can associate multiple responses with a notification" do
    notification = Factory.build(:notification)
    assert_difference('notification.responses.size', 2) do
      2.times { notification.responses << Factory.build(:notification_response) }
    end
  end

end
