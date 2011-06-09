class Enrollment < ActiveRecord::Base
  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :phone_number, :presence => true
  validates :delivery_method, :presence => true
  validates :stream_start, :presence => true
end
