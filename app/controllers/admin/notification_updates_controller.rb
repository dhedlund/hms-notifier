class Admin::NotificationUpdatesController < AdminController
  respond_to :html, :json

  def index
    @notification = Notification.find(params[:notification_id])
    @notification_updates = @notification.updates

    respond_with @notification_updates do |format|
      format.html { redirect_to [:admin, @notification] }
    end
  end

  def show
    @notification = Notification.find(params[:notification_id])
    @notification_update = @notification.updates.find(params[:id])
    respond_with @notification_update
  end

end
