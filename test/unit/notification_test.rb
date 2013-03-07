require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  setup do
    @notification = FactoryGirl.build(:notification)
  end

  test "valid notification should be valid" do
    assert FactoryGirl.build(:notification).valid?
  end

  test "delivered_at is optional" do
    assert FactoryGirl.build(:notification, :delivered_at => nil).valid?
  end

  #----------------------------------------------------------------------------#
  # status:
  #--------
  test "status should default to 'NEW'" do
    assert_equal Notification::NEW, FactoryGirl.build(:notification).status
  end

  test "should be invalid without a status" do
    notification = FactoryGirl.build(:notification)
    notification.status = nil
    assert notification.invalid?
  end

  test "should be invalid with an unknown status" do
    assert FactoryGirl.build(:notification, :status => 'BEWILDERED').invalid?
  end

  test "NEW is a valid status" do
    assert FactoryGirl.build(:notification, :status => Notification::NEW).valid?
  end

  test "TEMP_FAIL is a valid status" do
    assert FactoryGirl.build(:notification, :status => Notification::TEMP_FAIL).valid?
  end

  test "PERM_FAIL is a valid status" do
    assert FactoryGirl.build(:notification, :status => Notification::PERM_FAIL).valid?
  end

  test "DELIVERED is a valid status" do
    assert FactoryGirl.build(:notification, :status => Notification::DELIVERED).valid?
  end

  test "CANCELLED is a valid status" do
    assert FactoryGirl.build(:notification, :status => Notification::CANCELLED).valid?
  end

  test "changing from an active to an active status should be valid" do
    n = FactoryGirl.create(:notification, :status => Notification::NEW)
    n.status = Notification::TEMP_FAIL
    assert n.valid?
  end

  test "changing from an active to an inactive status should be valid" do
    n = FactoryGirl.create(:notification, :status => Notification::TEMP_FAIL)
    n.status = Notification::DELIVERED
    assert n.valid?
  end

  test "changing from inactive status to an inactive status should be valid" do
    n = FactoryGirl.create(:notification, :status => Notification::CANCELLED)
    n.status = Notification::PERM_FAIL
    assert n.valid?
  end

  test "changing from inactive status to an active status should be invalid" do
    n = FactoryGirl.create(:notification, :status => Notification::CANCELLED)
    n.status = Notification::TEMP_FAIL
    assert n.invalid?
  end

  #----------------------------------------------------------------------------#
  # uuid:
  #------
  test "uuid is optional" do
    assert FactoryGirl.build(:notification, :uuid => nil).valid?
  end

  test "two notifications cannot share the same uuid" do
    FactoryGirl.create(:notification, :uuid => 'abc123')
    assert FactoryGirl.build(:notification, :uuid => 'abc123').invalid?
  end

  test "uuid is auto-generated on save if none specified" do
    notification = FactoryGirl.create(:notification, :uuid => nil)
    assert_not_nil notification.uuid
  end

  test "uuid autogenerator should generate unique uuids" do
    n1 = FactoryGirl.create(:notification, :uuid => nil)
    n2 = FactoryGirl.create(:notification, :uuid => nil)
    assert_not_equal n1.uuid, n2.uuid
  end

  test "should not change uuid on save if already specified" do
    notification = FactoryGirl.create(:notification, :uuid => 'abc123')
    notification.save!
    assert_equal 'abc123', notification.uuid
  end

  #----------------------------------------------------------------------------#
  # delivery_date:
  #---------------
  test "should be invalid without a delivery_date" do
    notification = FactoryGirl.build(:notification)
    notification.delivery_date = nil
    notification.message = nil
    assert notification.invalid?
    assert notification.errors[:delivery_date]
  end

  test "should calculate delivery date if message and enrollment" do
    e = FactoryGirl.create(:enrollment, :stream_start => Date.parse('2011-03-24'))
    m = FactoryGirl.create(:message, :offset_days => 6)
    notification = Notification.new(:enrollment => e, :message => m)
    assert_equal Date.parse('2011-03-30'), notification.delivery_date
  end

  #----------------------------------------------------------------------------#
  # active?:
  #---------
  test "notification is active if it has a status of NEW" do
    assert FactoryGirl.build(:notification, :status => Notification::NEW).active?
  end

  test "notification is active if it has a status of TEMP_FAIL" do
    assert FactoryGirl.build(:notification, :status => Notification::TEMP_FAIL).active?
  end

  test "notification is not active if it has a status of PERM_FAIL" do
    assert !FactoryGirl.build(:notification, :status => Notification::PERM_FAIL).active?
  end

  test "notification is not active if it has a status of DELIVERED" do
    assert !FactoryGirl.build(:notification, :status => Notification::DELIVERED).active?
  end

  test "notification is not active if it has a status of CANCELLED" do
    assert !FactoryGirl.build(:notification, :status => Notification::CANCELLED).active?
  end

  #----------------------------------------------------------------------------#
  # cancelled?:
  #------------
  test "cancelled notifications should report themselves as being cancelled" do
    assert FactoryGirl.build(:notification, :status => Notification::CANCELLED).cancelled?
  end

  test "non-cancelled notifications should not report themselves as cancelled" do
    assert !FactoryGirl.build(:notification, :status => Notification::PERM_FAIL).cancelled?
  end

  #----------------------------------------------------------------------------#
  # relationship w/ Enrollment:
  #----------------------------
  test "should be invalid without an enrollment_id" do
    assert FactoryGirl.build(:notification, :enrollment_id => nil).invalid?
  end

  test "can access enrollment from notification" do
    assert FactoryGirl.build(:notification).enrollment
  end

  #----------------------------------------------------------------------------#
  # relationship w/ Message:
  #-------------------------
  test "should be invalid without a message_id" do
    assert FactoryGirl.build(:notification, :message_id => nil).invalid?
  end

  test "can access message from notification" do
    assert FactoryGirl.build(:notification).message
  end

  test "same message cannot exist twice for a single enrollment" do
    stream = FactoryGirl.create(:message_stream)
    message = FactoryGirl.create(:message, :message_stream => stream)
    enrollment = FactoryGirl.create(:enrollment, :message_stream => stream)
    FactoryGirl.create(:notification, :enrollment => enrollment, :message => message)
    assert FactoryGirl.build(:notification, :enrollment => enrollment, :message => message).invalid?
  end

  #----------------------------------------------------------------------------#
  # relationship w/ NotificationUpdate:
  #------------------------------------
  test "can associate multiple updates with a notification" do
    notification = FactoryGirl.build(:notification)
    assert_difference('notification.updates.size', 2) do
      2.times { notification.updates << FactoryGirl.build(:notification_update) }
    end
  end

  #----------------------------------------------------------------------------#
  # relationship w/ NotificationResponse:
  #--------------------------------------
  test "can associate multiple responses with a notification" do
    notification = FactoryGirl.build(:notification)
    assert_difference('notification.responses.size', 2) do
      2.times { notification.responses << FactoryGirl.build(:notification_response) }
    end
  end

  #----------------------------------------------------------------------------#
  # scopes:
  #--------
  test "active scope: returns notifications with statuses considered active" do
    enrollment = FactoryGirl.create(:enrollment)
    Notification::VALID_STATUSES.each do |status|
      m = FactoryGirl.create(:message, :message_stream => enrollment.message_stream)
      n = enrollment.notifications.create(:message => m, :status => status)
    end

    active_notifications = enrollment.notifications.active
    assert_equal Notification::ACTIVE_STATUSES.sort, active_notifications.map(&:status).sort
  end

  #----------------------------------------------------------------------------#
  # variables:
  #-----------
  test "should be valid without variables" do
    notification = FactoryGirl.build(:notification, :variables => nil)
    assert @notification.valid?
  end

  test "should return an empty hash by default" do
    notification = FactoryGirl.build(:notification, :variables => nil)
    assert_equal({}, notification.variables)
  end

end
