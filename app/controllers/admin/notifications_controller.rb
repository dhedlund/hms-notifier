class Admin::NotificationsController < AdminController
  respond_to :html, :json, :js

  def index
    @notifications = Notification.order('delivery_date DESC').page(params[:page])
    respond_with @notifications
  end

  def show
    @notification = Notification.find(params[:id])
    @notification_updates = @notification.updates
    @notification_responses = @notification.responses
    respond_with @notification
  end

end
