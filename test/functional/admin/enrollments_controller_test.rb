require 'test_helper'

class Admin::EnrollmentsControllerTest < ActionController::TestCase
  setup do
    @user = FactoryGirl.create(:user)
    creds = encode_credentials(@user.username, @user.password)
    @request.env['HTTP_AUTHORIZATION'] = creds

    @enrollment = FactoryGirl.build(:enrollment)
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
    4.times { FactoryGirl.create(:enrollment) }

    get :index, :format => :json
    assert_response :success
    assert_equal 4, json_response.count
  end

  test "show should return a enrollment (HTML)" do
    @enrollment.save!
    get :show, :id => @enrollment.id
    assert_response :success
    assert_not_nil assigns(:enrollment)
    assert_not_nil assigns(:notifications)
  end

  test "show should return a enrollment (JSON)" do
    @enrollment.save!
    get :show, :id => @enrollment.id, :format => :json
    assert_response :success
    assert_equal 'enrollment', json_response.keys.first
  end

  test "new should return a new enrollment form (HTML)" do
    get :new
    assert_response :success
    assert_not_nil assigns(:enrollment)
  end

  test "create should create a new enrollment (HTML)" do
    assert_difference('Enrollment.count') do
      post :create, :enrollment => @enrollment.attributes.symbolize_keys
    end
    assert_redirected_to [:admin, assigns(:enrollment)]
  end

  test "edit should return an existing enrollment form (HTML)" do
    @enrollment.save!
    get :edit, :id => @enrollment.id
    assert_response :success
    assert_equal @enrollment, assigns(:enrollment)
  end

  test "update should save an existing enrollment (HTML)" do
    @enrollment.save!
    @enrollment.first_name = 'Bleep'
    put :update, :id => @enrollment.id, :enrollment => @enrollment.attributes.symbolize_keys
    assert_redirected_to [:admin, assigns(:enrollment)]
  end

  test "destroy should remove an existing enrollment (HTML)" do
    @enrollment.save!
    assert_difference('Enrollment.count', -1) do
      delete :destroy, :id => @enrollment.id
    end

    assert_redirected_to [:admin, :enrollments]
    assert_equal @enrollment, assigns(:enrollment)
  end

end
