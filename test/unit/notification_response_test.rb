require 'test_helper'

class NotificationResponseTest < ActiveSupport::TestCase
  test "valid notification response should be valid" do
    assert Factory.build(:notification_response).valid?
  end

  test "should be invalid without a status" do
    assert Factory.build(:notification_response, :status => nil).invalid?
  end

  test "should be valid without an error_type" do
    assert Factory.build(:notification_response, :error_type => nil).valid?
  end

  test "should be valid without an error_msg" do
    assert Factory.build(:notification_response, :error_msg => nil).valid?
  end

  test "should be valid without a delivery_date" do
    assert Factory.build(:notification_response, :delivered_at => nil).valid?
  end

  #----------------------------------------------------------------------------#
  # relationship w/ Notification:
  #------------------------------
  test "should be invalid without a notification" do
    assert Factory.build(:notification_response, :notification => nil).invalid?
  end

  test "can access notification from notification response" do
    assert Factory.build(:notification_response).notification
  end

end
