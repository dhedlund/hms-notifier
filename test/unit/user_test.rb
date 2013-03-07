require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "valid user should be valid" do
    assert FactoryGirl.build(:user).valid?
  end

  #----------------------------------------------------------------------------#
  # username:
  #----------
  test "should be invalid without a username" do
    assert FactoryGirl.build(:user, :username => nil).invalid?
  end

  test "cannot have two users with the same username" do
    FactoryGirl.create(:user, :username => 'myuser')
    assert FactoryGirl.build(:user, :username => 'myuser').invalid?
  end

  #----------------------------------------------------------------------------#
  # password:
  #----------
  test "should be invalid without a password" do
    assert FactoryGirl.build(:user, :password => nil).invalid?
  end

  #----------------------------------------------------------------------------#
  # timezone:
  #----------
  test "should be invalid without a timezone" do
    assert FactoryGirl.build(:user, :timezone => nil).invalid?
  end

end
