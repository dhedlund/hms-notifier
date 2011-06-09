class MessageStream < ActiveRecord::Base
  has_many :messages
  has_many :enrollments

  validates :name,  :presence => true, :uniqueness => true
  validates :title, :presence => true
end
