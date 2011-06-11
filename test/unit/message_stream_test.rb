require 'test_helper'

class MessageStreamTest < ActiveSupport::TestCase
  test "valid message stream should be valid" do
    assert Factory.build(:message_stream).valid?
  end

  test "should be invalid without a name" do
    assert Factory.build(:message_stream, :name => nil).invalid?
  end

  test "should be invalid without a title" do
    assert Factory.build(:message_stream, :title => nil).invalid?
  end

  test "cannot have two message streams with the same name" do
    Factory.create(:message_stream, :name => 'mystream')
    assert Factory.build(:message_stream, :name => 'mystream').invalid?
  end

  test "can associate multiple messages with a message stream" do
    stream = Factory.build(:message_stream)
    stream.messages << Factory.build(:message)
    stream.messages << Factory.build(:message)
    assert_equal 2, stream.messages.size
  end

  test "cannot have two messages with same name in same stream" do
    stream = Factory.create(:message_stream)
    Factory.create(:message, :name => 'mymessage', :message_stream => stream)
    assert Factory.build(:message, :name => 'mymessage',
      :message_stream => stream).invalid?
  end

  test "should be sorted by name in ascending order" do
    ['w','b','e','x','n'].each do |name|
      Factory.create(:message_stream, :name => name)
    end
    assert_equal MessageStream.all.map(&:name).sort, MessageStream.all.map(&:name)
  end


  #----------------------------------------------------------------------------#
  # relationship w/ Enrollment:
  #----------------------------
  test "can access enrollments from message stream" do
    assert Factory.create(:message_stream).enrollments
  end

  test "can associate multiple enrollments with a message stream" do
    stream = Factory.build(:message_stream)
    stream.enrollments << Factory.build(:enrollment)
    stream.enrollments << Factory.build(:enrollment)
    assert_equal 2, stream.enrollments.size
  end

end
