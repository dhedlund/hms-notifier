require 'test_helper'

class Admin::NotificationUpdatesControllerTest < ActionController::TestCase
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

  test "index should redirect to notification_update notification show page (HTML)" do
    notification = Factory.create(:notification)

    get :index, :notification_id => notification.id
    assert_redirected_to [:admin, notification]
  end

  test "index should return a list of notification_updates (JSON)" do
    notification = Factory.create(:notification)
    4.times { Factory.create(:notification_update, :notification => notification) }

    get :index, :notification_id => notification.id, :format => :json
    assert_response :success
    assert_equal 4, json_response.count
  end

  test "show should return a notification_update (HTML)" do
    notification_update = Factory.create(:notification_update)

    get :show, :notification_id => notification_update.notification.id, :id => notification_update.id
    assert_response :success
    assert_not_nil assigns(:notification)
    assert_not_nil assigns(:notification_update)
  end

  test "show should return a notification_update (JSON)" do
    notification_update = Factory.create(:notification_update)

    get :show, :notification_id => notification_update.notification.id, :id => notification_update.id, :format => :json
    assert_response :success
    assert_equal 'notification_update', json_response.keys.first
  end

end
