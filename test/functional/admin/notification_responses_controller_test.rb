require 'test_helper'

class Admin::NotificationResponsesControllerTest < ActionController::TestCase
  setup do
    @user = Factory.create(:user)

    creds = encode_credentials(@user.username, @user.password)
    @request.env['HTTP_AUTHORIZATION'] = creds
  end

  test "accessing controller w/o creds should give 401 unauthorized" do
    @request.env['HTTP_AUTHORIZATION'] = nil
    notification = Factory.create(:notification)

    get :index, :notification_id => notification.id
    assert_response 401
  end

  test "index should redirect to notification_response notification show page (HTML)" do
    notification = Factory.create(:notification)

    get :index, :notification_id => notification.id
    assert_redirected_to [:admin, notification]
  end

  test "index should return a list of notification_responses (JSON)" do
    notification = Factory.create(:notification)
    4.times { Factory.create(:notification_response, :notification => notification) }

    get :index, :notification_id => notification.id, :format => :json
    assert_response :success
    assert_equal 4, json_response.count
  end

  test "show should return a notification_response (HTML)" do
    notification_response = Factory.create(:notification_response)

    get :show, :notification_id => notification_response.notification.id, :id => notification_response.id
    assert_response :success
    assert_not_nil assigns(:notification)
    assert_not_nil assigns(:notification_response)
  end

  test "show should return a notification_response (JSON)" do
    notification_response = Factory.create(:notification_response)

    get :show, :notification_id => notification_response.notification.id, :id => notification_response.id, :format => :json
    assert_response :success
    assert_equal 'notification_response', json_response.keys.first
  end

end
