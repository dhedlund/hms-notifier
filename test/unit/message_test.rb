require 'test_helper'

class MessagesTest < ActiveSupport::TestCase
  test "valid message should be valid" do
    assert Factory.build(:message).valid?
  end

  test "should be invalid without a message stream id" do
    assert Factory.build(:message, :message_stream_id => nil).invalid?
  end

  test "should be invalid without a name" do
    assert Factory.build(:message, :name => nil).invalid?
  end

  test "should be invalid without a title" do
    assert Factory.build(:message, :title => nil).invalid?
  end

  test "should be valid without a language" do
    assert Factory.build(:message, :language => nil).valid?
  end

  test "should be sorted by offset_days in ascending order" do
    s = Factory.create(:message_stream)
    [10,6,29,8,3].each do |offset|
      Factory.create(:message, :message_stream => s, :offset_days => offset)
    end
    assert_equal s.messages.map(&:offset_days).sort, s.messages.map(&:offset_days)
  end

  #----------------------------------------------------------------------------#
  # expire_days:
  #-------------
  test "should be valid without an expire_days" do
    message = Factory.build(:message, :expire_days => nil)
    assert message.valid?
  end

  test "should be able to assign an integer to expire_days" do
    message = Factory.build(:message, :expire_days => 5)
    assert_equal 5, message.expire_days
  end

  #----------------------------------------------------------------------------#
  # offset_days:
  #-------------
  test "should be invalid without an offset" do
    assert Factory.build(:message, :offset_days => nil).invalid?
  end

  test "days offset must be a whole number" do
    assert Factory.build(:message, :offset_days => 2.25).invalid?
  end

  test "negative day offsets are invalid" do
    assert Factory.build(:message, :offset_days => -5).invalid?
  end

  test "zero day offsets are valid" do
    assert Factory.build(:message, :offset_days => 0).valid?
  end

  #----------------------------------------------------------------------------#
  # path:
  #------
  test "can get a unique path to represent message across message streams" do
    message = Factory.build(:message)
    assert_equal "#{message.message_stream.name}/#{message.name}",
      message.path
  end

  test "path should return nil if not enough info to build path" do
    assert_nil Factory.build(:message, :message_stream => nil).path
    assert_nil Factory.build(:message, :name => nil).path
  end

  test "can search for a message by its path" do
    message = Factory.create(:message)
    assert_equal message, Message.find_by_path(message.path)
  end

  test "searching for a message by a nonexistent path should return nil" do
    assert_nil Message.find_by_path('nonexistent/path')
  end

  #----------------------------------------------------------------------------#
  # relationship w/ MessageStream:
  #-------------------------------
  test "can access message stream from message" do
    assert Factory.build(:message).message_stream
  end

  #----------------------------------------------------------------------------#
  # scopes:
  #--------
  test "notifiable: messages with offsets between -1 and 5 days from offset" do
    stream = Factory.create(:message_stream)
    (3..12).each do |d|
      Factory.create(:message, :message_stream => stream, :offset_days => d)
    end

    assert_equal 3, stream.messages.notifiable(0).count, "count failed for 5"
    assert_equal 7, stream.messages.notifiable(5).count, "count failed for 5"
    assert_equal 1, stream.messages.notifiable(13).count, "count failed for 13"

    [0,5,13].each do |offset|
      results = stream.messages.notifiable(offset).map(&:offset_days)
      assert(results.all? { |d| d >= offset - 1 && d <= offset + 5 },
        "failed for offset #{offset}, got: #{results.to_sentence}")
    end
  end

  #----------------------------------------------------------------------------#
  # sms_text:
  #----------
  test "should be valid without an sms_text" do
    message = Factory.build(:message)
    message.sms_text = nil
    assert message.valid?
  end

end


