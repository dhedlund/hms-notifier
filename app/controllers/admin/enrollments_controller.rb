class Admin::EnrollmentsController < AdminController
  respond_to :html, :json, :js

  def index
    @enrollments = Enrollment.page(params[:page])
    respond_with :admin, @enrollments
  end

  def show
    @enrollment = Enrollment.find(params[:id])
    @notifications = @enrollment.notifications
    respond_with :admin, @enrollment
  end

  def new
    @enrollment = Enrollment.new
    respond_with :admin, @enrollment
  end

  def edit
    @enrollment = Enrollment.find(params[:id])
    respond_with :admin, @enrollment
  end

  def create
    @enrollment = Enrollment.new
    @enrollment.attributes = params[:enrollment]
    @enrollment.save
    respond_with :admin, @enrollment
  end

  def update
    @enrollment = Enrollment.find(params[:id])
    @enrollment.update_attributes(params[:enrollment])
    respond_with :admin, @enrollment
  end

  def destroy
    @enrollment = Enrollment.find(params[:id])
    @enrollment.destroy
    respond_with :admin, @enrollment
  end

end
