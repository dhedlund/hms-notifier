class Admin::EnrollmentsController < AdminController
  respond_to :html, :json

  def index
    @enrollments = Enrollment.scoped
    respond_with @enrollments
  end

  def show
    @enrollment = Enrollment.find(params[:id])
    respond_with @enrollment
  end

end
