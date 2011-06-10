class Admin::NotificationResponsesController < AdminController
  respond_to :html, :json

  def index
    @notification = Notification.find(params[:notification_id])
    @notification_responses = @notification.responses

    respond_with @notification_responses do |format|
      format.html { redirect_to [:admin, @notification] }
    end
  end

  def show
    @notification = Notification.find(params[:notification_id])
    @notification_response = @notification.responses.find(params[:id])
    respond_with @notification_response
  end

end
