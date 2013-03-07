class HotlineUser < ActiveRecord::Base
  establish_connection Rails.configuration.database_configuration["openmrs"] 
  self.table_name = 'users'
end
