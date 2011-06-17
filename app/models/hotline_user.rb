class HotlineUser < ActiveRecord::Base
  establish_connection Rails.configuration.database_configuration["openmrs"] 
  set_table_name "users"
end
