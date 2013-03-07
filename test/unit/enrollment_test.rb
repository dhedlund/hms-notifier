require 'test_helper'

class EnrollmentTest < ActiveSupport::TestCase
  setup do
    @enrollment = FactoryGirl.build(:enrollment)
    @stream = @enrollment.message_stream
  end

  test "valid enrollment is valid" do
    assert FactoryGirl.build(:enrollment).valid?
  end

  test "should be invalid without a first_name" do
    assert FactoryGirl.build(:enrollment, :first_name => nil).invalid?
  end

  test "should be valid without a last_name" do
    assert FactoryGirl.build(:enrollment, :last_name => nil).valid?
  end

  test "should be invalid without a delivery_method" do
    assert FactoryGirl.build(:enrollment, :delivery_method => nil).invalid?
  end

  test "should be invalid without a stream_start date" do
    assert FactoryGirl.build(:enrollment, :stream_start => nil).invalid?
  end

  test "should be valid without a preferred time" do
    assert FactoryGirl.build(:enrollment, :preferred_time => nil).valid?
  end

  test "should be valid without a language" do
    assert FactoryGirl.build(:enrollment, :language => nil).valid?
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
  # enqueue_ready_messages:
  #------------------------
  test "enqueue_ready_messages should get a list of ready messages" do
    @enrollment.save!
    @enrollment.expects(:ready_messages).returns([])
    @enrollment.enqueue_ready_messages
  end

  test "enqueue_ready_messages should create notifications from messages" do
    @enrollment.save!
    messages = 3.times.map do
      FactoryGirl.create(:message, :message_stream => @enrollment.message_stream)
    end

    @enrollment.expects(:ready_messages).returns(messages)
    assert_difference('@enrollment.notifications.count', 3) do
      @enrollment.enqueue_ready_messages
    end
  end


  #----------------------------------------------------------------------------#
  # ext_user_id:
  #-------------
  test "should be valid without an ext_user_id" do
    assert FactoryGirl.build(:enrollment, :ext_user_id => nil).valid?
  end

  test "should prevent two active enrollments w/ same ext_user_id & stream" do
    FactoryGirl.create(:enrollment, :message_stream => @stream, :ext_user_id => 'foo')
    e = FactoryGirl.build(:enrollment, :message_stream => @stream, :ext_user_id => 'foo')
    assert e.invalid?
    assert e.errors[:base].any?
  end

  test "should allow two active enrollments w/ same ext_user_id if diff streams" do
    FactoryGirl.create(:enrollment, :ext_user_id => 'foo')
    assert FactoryGirl.build(:enrollment, :ext_user_id => 'foo').valid?
  end

  #----------------------------------------------------------------------------#
  # supported_languages:
  #---------------------
  test "supported_languages should return list of unique message languages" do
    stream = @enrollment.message_stream
    2.times { FactoryGirl.create(:message, :message_stream => stream, :language => 'English') }
    FactoryGirl.create(:message, :message_stream => stream, :language => 'Spanish')
    assert_equal ['English', 'Spanish'], Enrollment.supported_languages.sort
  end

  #----------------------------------------------------------------------------#
  # status:
  #--------
  test "status should default to 'ACTIVE'" do
    assert_equal Enrollment::ACTIVE, FactoryGirl.build(:enrollment).status
  end

  test "should be invalid without a status" do
    enrollment = FactoryGirl.build(:enrollment)
    enrollment.status = nil
    assert enrollment.invalid?
  end

  test "should be invalid with an unknown status" do
    assert FactoryGirl.build(:enrollment, :status => 'CONFUSED').invalid?
  end

  test "ACTIVE is a valid status" do
    assert FactoryGirl.build(:enrollment, :status => Enrollment::ACTIVE).valid?
  end

  test "COMPLETED is a valid status" do
    assert FactoryGirl.build(:enrollment, :status => Enrollment::COMPLETED).valid?
  end

  test "CANCELLED is a valid status" do
    assert FactoryGirl.build(:enrollment, :status => Enrollment::CANCELLED).valid?
  end

  test "setting status to cancelled should also cancel active notifications" do
    enrollment = FactoryGirl.create(:enrollment)
    3.times do
      m = FactoryGirl.create(:message, :message_stream => enrollment.message_stream)
      enrollment.notifications.create(:message => m)
    end

    enrollment.update_attributes(:status => Enrollment::CANCELLED)
    assert enrollment.notifications.all?(&:cancelled?)
  end

  test "setting status to cancelled should not cancel inactive notifications" do
    enrollment = FactoryGirl.create(:enrollment)
    3.times do
      m = FactoryGirl.create(:message, :message_stream => enrollment.message_stream)
      enrollment.notifications.create(:message => m, :status => Notification::PERM_FAIL)
    end

    enrollment.update_attributes(:status => Enrollment::CANCELLED)
    assert enrollment.notifications.none?(&:cancelled?)
  end

  #----------------------------------------------------------------------------#
  # phone_number:
  #--------------
  test "should be invalid without a phone_number" do
    assert FactoryGirl.build(:enrollment, :phone_number => nil).invalid?
  end

  test "should be able to store symbols with phone numbers (i.e. country)" do
    enrollment = FactoryGirl.build(:enrollment, :phone_number => '+11 (4) 302 1432')
    assert_equal '+11 (4) 302 1432', enrollment.phone_number
  end

  test "should be able to create multiple enrollments with same phone number" do
    assert_difference('Enrollment.count', 2) do
      2.times { enrollment = FactoryGirl.create(:enrollment, :phone_number => '12345') }
    end
  end

  test "should not be able to create two active enrollments to same stream" do
    stream = FactoryGirl.create(:message_stream)
    enrollments = 2.times.map do
      FactoryGirl.build(:enrollment,
        :phone_number => '12345',
        :message_stream => stream,
        :status => Enrollment::ACTIVE
      )
    end
    assert enrollments.first.save
    assert enrollments.last.invalid?
  end

  test "should be able to create new active enrollment if one inactive" do
    stream = FactoryGirl.create(:message_stream)
    FactoryGirl.create(:enrollment,
      :phone_number => '12345',
      :message_stream => stream,
      :status => Enrollment::COMPLETED
    )
    enrollment = FactoryGirl.build(:enrollment,
      :phone_number => '12345',
      :message_stream => stream,
      :status => Enrollment::ACTIVE
    )
    assert enrollment.save
  end

  test "should be able to reactivate an enrollment if both inactive" do
    stream = FactoryGirl.create(:message_stream)
    enrollments = 2.times.map do
      FactoryGirl.create(:enrollment,
        :phone_number => '12345',
        :message_stream => stream,
        :status => Enrollment::CANCELLED
      )
    end
    enrollment = enrollments.last
    enrollment.status = Enrollment::ACTIVE
    assert enrollment.save
  end

  test "should not be able to reactive second enrollment if first active" do
    stream = FactoryGirl.create(:message_stream)
    enrollments = 2.times.map do
      FactoryGirl.create(:enrollment,
        :phone_number => '12345',
        :message_stream => stream,
        :status => Enrollment::CANCELLED
      )
    end
    enrollments.first.update_attributes(:status => Enrollment::ACTIVE)
    enrollment = enrollments.last
    enrollment.status = Enrollment::ACTIVE
    assert !enrollment.save
  end

  #----------------------------------------------------------------------------#
  # ready_messages:
  #----------------
  test "ready_messages should get messages within notifiable range (-1 to 5)" do
    stream = FactoryGirl.create(:message_stream)
    messages = (3..15).map do |d|
      FactoryGirl.create(:message, :message_stream => stream, :offset_days => d)
    end

    enrollment = FactoryGirl.create(:enrollment,
      :message_stream => stream,
      :stream_start => Date.today - 6
    )

    assert_equal messages[2..8], enrollment.ready_messages
  end

  test "ready_messages should not include messages already as notifications" do
    stream = FactoryGirl.create(:message_stream)
    messages = (3..15).map do |d|
      FactoryGirl.create(:message, :message_stream => stream, :offset_days => d)
    end

    enrollment = FactoryGirl.create(:enrollment,
      :message_stream => stream,
      :stream_start => Date.today - 6
    )

    enrollment.notifications.create!(:message_id => messages[4].id)
    enrollment.notifications.create!(:message_id => messages[5].id)
    assert enrollment.ready_messages.exclude?(messages[4])
    assert enrollment.ready_messages.exclude?(messages[5])
  end

  test "should not return any ready messages if enrollment is not active" do
    stream = FactoryGirl.create(:message_stream)
    messages = (3..15).map do |d|
      FactoryGirl.create(:message, :message_stream => stream, :offset_days => d)
    end

    enrollment = FactoryGirl.create(:enrollment,
      :message_stream => stream,
      :stream_start => Date.today - 6,
      :status => Enrollment::CANCELLED
    )

    assert enrollment.ready_messages.empty?

  end

  #----------------------------------------------------------------------------#
  # active?:
  #---------
  test "enrollment is active if it has a status of ACTIVE" do
    assert FactoryGirl.build(:enrollment, :status => Enrollment::ACTIVE).active?
  end

  test "enrollment is not active if it has a status of COMPLETED" do
    assert !FactoryGirl.build(:enrollment, :status => Enrollment::COMPLETED).active?
  end

  test "enrollment is not active if it has a status of CANCELLED" do
    assert !FactoryGirl.build(:enrollment, :status => Enrollment::CANCELLED).active?
  end

  #----------------------------------------------------------------------------#
  # cancelled?:
  #------------
  test "cancelled enrollments should report themselves as being cancelled" do
    assert FactoryGirl.build(:enrollment, :status => Enrollment::CANCELLED).cancelled?
  end

  test "non-cancelled enrollments should not report themselves as cancelled" do
    assert !FactoryGirl.build(:enrollment, :status => Enrollment::COMPLETED).cancelled?
  end

  #----------------------------------------------------------------------------#
  # relationship w/ MessageStream:
  #-------------------------------
  test "can access message stream from enrollment" do
    assert FactoryGirl.build(:enrollment).message_stream
  end

  test "should be invalid without a message_stream_id" do
    enrollment = FactoryGirl.build(:enrollment)
    enrollment.message_stream_id = nil
    assert enrollment.invalid?
    assert enrollment.errors[:message_stream_id].any?
  end

  #----------------------------------------------------------------------------#
  # relationship w/ Notification:
  #------------------------------
  test "can associate multiple notifications with an enrollment" do
    enrollment = FactoryGirl.build(:enrollment)
    assert_difference('enrollment.notifications.size', 2) do
      2.times { enrollment.notifications << FactoryGirl.build(:notification) }
    end
  end

  #----------------------------------------------------------------------------#
  # scopes:
  #--------
  test "active scope: returns enrollments with an ACTIVE status" do
    stream = FactoryGirl.create(:message_stream)
    Enrollment::VALID_STATUSES.each do |status|
      FactoryGirl.create(:enrollment, :message_stream => stream, :status => status)
    end

    active_enrollments = Enrollment.active
    assert_equal 1, active_enrollments.size
    assert_equal Enrollment::ACTIVE, active_enrollments[0].status
  end

  test "completed scope: returns enrollments with a COMPLETED status" do
    stream = FactoryGirl.create(:message_stream)
    Enrollment::VALID_STATUSES.each do |status|
      FactoryGirl.create(:enrollment, :message_stream => stream, :status => status)
    end

    completed_enrollments = Enrollment.completed
    assert_equal 1, completed_enrollments.size
    assert_equal Enrollment::COMPLETED, completed_enrollments[0].status
  end

  test "cancelled scope: returns enrollments with a CANCELLED status" do
    stream = FactoryGirl.create(:message_stream)
    Enrollment::VALID_STATUSES.each do |status|
      FactoryGirl.create(:enrollment, :message_stream => stream, :status => status)
    end

    cancelled_enrollments = Enrollment.cancelled
    assert_equal 1, cancelled_enrollments.size
    assert_equal Enrollment::CANCELLED, cancelled_enrollments[0].status
  end

  #----------------------------------------------------------------------------#
  # variables:
  #-----------
  test "should be valid without variables" do
    @enrollment.variables = {}
    assert @enrollment.valid?
  end

  test "should return an empty hash by default" do
    @enrollment.variables = {}
    assert_equal({}, @enrollment.variables)
  end

end
