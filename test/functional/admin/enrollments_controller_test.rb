require 'test_helper'

class Admin::EnrollmentsControllerTest < ActionController::TestCase
  setup do
    @user = Factory.create(:user)
    creds = encode_credentials(@user.username, @user.password)
    @request.env['HTTP_AUTHORIZATION'] = creds
  end

  test "accessing controller w/o creds should give 401 unauthorized" do
    @request.env['HTTP_AUTHORIZATION'] = nil
    get :index
    assert_response 401
  end

  test "index should return a list of enrollments (HTML)" do
    get :index
    assert_response :success
    assert_not_nil assigns(:enrollments)
  end

  test "index should return a list of enrollments (JSON)" do
    4.times { Factory.create(:enrollment) }

    get :index, :format => :json
    assert_response :success
    assert_equal 4, json_response.count
  end

  test "show should return a enrollment (HTML)" do
    enrollment = Factory.create(:enrollment)

    get :show, :id => enrollment.id
    assert_response :success
    assert_not_nil assigns(:enrollment)
    assert_not_nil assigns(:notifications)
  end

  test "show should return a enrollment (JSON)" do
    enrollment = Factory.create(:enrollment)

    get :show, :id => enrollment.id, :format => :json
    assert_response :success
    assert_equal 'enrollment', json_response.keys.first
  end

end
