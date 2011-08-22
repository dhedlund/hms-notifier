class Admin::UsersController < AdminController
  respond_to :html, :json, :js

  def index
    @users = User.page(params[:page])
    respond_with @users do |format|
      format.json { render :json => @users, :except => 'password' }
    end
  end

  def show
    @user = User.find(params[:id])
    respond_with @user do |format|
      format.json { render :json => @user, :except => 'password' }
    end
  end

end
