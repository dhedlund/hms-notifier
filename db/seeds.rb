# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# populates message_streams
Dir[File.expand_path('../seed_data/message_streams/*.yml', __FILE__)].each do |file|
  data = YAML.load_file(file)
  stream = MessageStream.create!(:name => data['name'], :title => data['title'])
  data['messages'].each do |data|
    message = Message.create!(
      :message_stream_id => stream.id,
      :name => data['name'],
      :title => data['title'],
      :offset_days => data['offset_days']
    )
  end
end
