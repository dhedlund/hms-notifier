class StatusChecksController < ActionController::Base
  respond_to :html
  def two_dbs
    @hotline_users = HotlineUser.all
    @users = User.all
  end

end
