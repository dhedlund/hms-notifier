require 'test_helper'

class EnrollmentTest < ActiveSupport::TestCase
  setup do
    @enrollment = Factory.build(:enrollment)
  end

  test "valid enrollment is valid" do
    assert Factory.build(:enrollment).valid?
  end

  test "should be invalid without a first_name" do
    assert Factory.build(:enrollment, :first_name => nil).invalid?
  end

  test "should be invalid without a last_name" do
    assert Factory.build(:enrollment, :last_name => nil).invalid?
  end

  test "should be invalid without a delivery_method" do
    assert Factory.build(:enrollment, :delivery_method => nil).invalid?
  end

  test "should be invalid without a stream_start date" do
    assert Factory.build(:enrollment, :stream_start => nil).invalid?
  end

  test "should be valid without a preferred time" do
    assert Factory.build(:enrollment, :preferred_time => nil).valid?
  end

  test "should be valid without an ext_user_id" do
    assert Factory.build(:enrollment, :ext_user_id => nil).valid?
  end

  test "should be able to retrieve the created_at date" do
    @enrollment.save!
    assert_not_nil @enrollment.created_at
  end

  test "should be able to retrieve the updated_at date" do
    @enrollment.save!
    assert_not_nil @enrollment.updated_at
  end

  #----------------------------------------------------------------------------#
  # status:
  #--------
  test "status should default to 'ACTIVE'" do
    assert_equal Enrollment::ACTIVE, Factory.build(:enrollment).status
  end

  test "should be invalid without a status" do
    enrollment = Factory.build(:enrollment)
    enrollment.status = nil
    assert enrollment.invalid?
  end

  test "should be invalid with an unknown status" do
    assert Factory.build(:enrollment, :status => 'CONFUSED').invalid?
  end

  test "ACTIVE is a valid status" do
    assert Factory.build(:enrollment, :status => Enrollment::ACTIVE).valid?
  end

  test "COMPLETED is a valid status" do
    assert Factory.build(:enrollment, :status => Enrollment::COMPLETED).valid?
  end

  test "CANCELLED is a valid status" do
    assert Factory.build(:enrollment, :status => Enrollment::CANCELLED).valid?
  end

  #----------------------------------------------------------------------------#
  # phone_number:
  #--------------
  test "should be invalid without a phone_number" do
    assert Factory.build(:enrollment, :phone_number => nil).invalid?
  end

  test "should be able to store symbols with phone numbers (i.e. country)" do
    enrollment = Factory.build(:enrollment, :phone_number => '+11 (4) 302 1432')
    assert_equal '+11 (4) 302 1432', enrollment.phone_number
  end

  #----------------------------------------------------------------------------#
  # ready_messages:
  #----------------
  test "ready_messages should get messages within notifiable range (-1 to 5)" do
    stream = Factory.create(:message_stream)
    messages = (3..15).map do |d|
      Factory.create(:message, :message_stream => stream, :offset_days => d)
    end

    enrollment = Factory.create(:enrollment,
      :message_stream => stream,
      :stream_start => Date.today - 6
    )

    assert_equal messages[2..8], enrollment.ready_messages
  end

  test "ready_messages should not include messages already as notifications" do
    stream = Factory.create(:message_stream)
    messages = (3..15).map do |d|
      Factory.create(:message, :message_stream => stream, :offset_days => d)
    end

    enrollment = Factory.create(:enrollment,
      :message_stream => stream,
      :stream_start => Date.today - 6
    )

    enrollment.notifications.create!(:message_id => messages[4].id)
    enrollment.notifications.create!(:message_id => messages[5].id)
    assert enrollment.ready_messages.exclude?(messages[4])
    assert enrollment.ready_messages.exclude?(messages[5])
  end

  #----------------------------------------------------------------------------#
  # active?:
  #---------
  test "enrollment is active if it has a status of ACTIVE" do
    assert Factory.build(:enrollment, :status => Enrollment::ACTIVE).active?
  end

  test "enrollment is not active if it has a status of COMPLETED" do
    assert !Factory.build(:enrollment, :status => Enrollment::COMPLETED).active?
  end

  test "enrollment is not active if it has a status of CANCELLED" do
    assert !Factory.build(:enrollment, :status => Enrollment::CANCELLED).active?
  end

  #----------------------------------------------------------------------------#
  # cancelled?:
  #------------
  test "cancelled enrollments should report themselves as being cancelled" do
    assert Factory.build(:enrollment, :status => Enrollment::CANCELLED).cancelled?
  end

  test "non-cancelled enrollments should not report themselves as cancelled" do
    assert !Factory.build(:enrollment, :status => Enrollment::COMPLETED).cancelled?
  end

  #----------------------------------------------------------------------------#
  # relationship w/ MessageStream:
  #-------------------------------
  test "can access message stream from enrollment" do
    assert Factory.build(:enrollment).message_stream
  end

  #----------------------------------------------------------------------------#
  # relationship w/ Notification:
  #------------------------------
  test "can associate multiple notifications with an enrollment" do
    enrollment = Factory.build(:enrollment)
    assert_difference('enrollment.notifications.size', 2) do
      2.times { enrollment.notifications << Factory.build(:notification) }
    end
  end

end
