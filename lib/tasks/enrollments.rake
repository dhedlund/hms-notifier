
namespace :enrollments do
  desc "test enrollments query"  
  task :query => :environment do
    logger = RAILS_DEFAULT_LOGGER

    class EncounterType < ActiveRecord::Base
      establish_connection Rails.configuration.database_configuration["openmrs"] 
      set_table_name :encounter_type
    end

    class Encounter < ActiveRecord::Base
      establish_connection Rails.configuration.database_configuration["openmrs"] 
      set_table_name :encounter
      def self.valid_by_type(type_name)
        where(:voided=>false, :encounter_type=>EncounterType.find_by_name(type_name).encounter_type_id)
      end
      def self.tips; valid_by_type("TIPS AND REMINDERS"); end
      def self.pg_status; valid_by_type("PREGNANCY STATUS"); end

      def obs_hash(allow_nil=false)
        Hash[*Observation.where(:encounter_id=>encounter_id).all.map(&:key_and_value).flatten]
      end

    end

    class Observation < ActiveRecord::Base
      establish_connection Rails.configuration.database_configuration["openmrs"] 
      set_table_name :obs
      def value
        #all relevant ones seem to be either text or coded
        value_text || value_decoded
      end
      def value_decoded; ConceptName.for_concept_id(value_coded).name; end
      def label; ConceptName.for_concept_id(concept_id).name; end
      def key_and_value;  [label, value]; end
    end

    class ConceptName  < ActiveRecord::Base
      establish_connection Rails.configuration.database_configuration["openmrs"] 
      set_table_name :concept_name
      def self.for_concept_id(concept_id)
        #multiple names per concept
        where(:concept_id => concept_id).first
      end
    end

    class Patient < ActiveRecord::Base
      establish_connection Rails.configuration.database_configuration["openmrs"] 
      set_table_name :patient
    end

    national_id_type_id = Patient.find_by_sql("SELECT patient_identifier_type_id 
    FROM patient_identifier_type WHERE name='National id'").first.patient_identifier_type_id
    ivr_id_type_id = Patient.find_by_sql("SELECT patient_identifier_type_id 
    FROM patient_identifier_type WHERE name='IVR Access Code'").first.patient_identifier_type_id
    class Person < ActiveRecord::Base
      establish_connection Rails.configuration.database_configuration["openmrs"] 
      set_table_name :person
    end
    class PersonName < ActiveRecord::Base
      establish_connection Rails.configuration.database_configuration["openmrs"] 
      set_table_name :person_name
    end

    content_type_to_stream = {
      "CHILD" => "child",
      "PREGNANCY" => "pregnancy"
    }

    lang_to_lang = {
      "CHICHEWA" => "Default Language",
      "CHIYAO" => "Yao"
    } 
    message_type_to_delivery = {
      "SMS" => "SMS",
      "VOICE" => "IVR"
    }

    enrollment_ids_to_cancel = Enrollment.active.map(&:id)

    #  desc "show verbose enrollment-related query results"
    #  task :show => :environment, :openmrs_models do
    all_tips_encounters=Encounter.tips.order("patient_id ASC, date_created ASC")
    all_tips_encounters_by_patient= all_tips_encounters.group_by(&:patient_id)
    puts "#{all_tips_encounters_by_patient.size} patients"
    all_tips_encounters_by_patient.each do |patient_id, encounters|
      patient_name = PersonName.find_by_person_id(patient_id)
      first_name = patient_name.given_name
      last_name = patient_name.family_name

      #      puts "#{first_name} #{last_name} (#{patient_id})"

      national_id = Patient.find_by_sql("SELECT identifier FROM patient_identifier 
      WHERE patient_id = #{patient_id} AND identifier_type = #{national_id_type_id}").first.identifier
      ivr_id = Patient.find_by_sql("SELECT identifier FROM patient_identifier 
      WHERE patient_id = #{patient_id} AND identifier_type = #{ivr_id_type_id}").first.identifier
      ext_user_id = "#{ivr_id}/#{national_id}"

      encounter_data = encounters.last.obs_hash

      phone = (encounter_data["PHONE NUMBER"] || encounter_data["TELEPHONE NUMBER"]).gsub(" ","")
      person_log_summary = "#{first_name} #{last_name} #{phone} #{ext_user_id} (#{patient_id})"

      puts "#{person_log_summary}"
      puts "     #{encounters.size} total, last #{encounters.last.date_created}  #{encounters.last.encounter_id}: #{encounter_data.inspect}"

      next unless encounter_data["ON TIPS AND REMINDERS PROGRAM"] == "YES"

      #all further 'next' skips are unexpected and should be logged as warnings
      #the intent is to catch holes in mnch-hotline's minimal enrollment validation logic. 
      skip_text = "Enrollment skipped for #{person_log_summary}:\n      "


      unless stream_name = content_type_to_stream[encounter_data["TYPE OF MESSAGE CONTENT"]]
        puts "Unsupported message type #{encounter_data["TYPE OF MESSAGE CONTENT"]} for #{person_log_summary}"
        next
      end

      stream = MessageStream.find_by_name(stream_name) 
      raise "stream not found for name #{stream_name}" if stream.nil?
      if stream_name=="child"
        stream_start = Person.find_by_person_id(patient_id).birthdate
      elsif stream_name=="pregnancy"
        pg_status_encounter = Encounter.pg_status.where(:patient_id=>patient_id).order("date_created DESC").first 
        if pg_status_encounter.nil?
          puts "#{skip_text} Pregnancy enrollment without pregancy status encounter"
          next
        end
        # curiously, EDD is stored as value_text, and has two possible names
        due_date_text = pg_status_encounter.obs_hash["PREGNANCY DUE DATE"] || pg_status_encounter.obs_hash["EXPECTED DUE DATE"]
        if due_date_text.nil?
          puts "#{skip_text} Pregnancy enrollment with pregnancy status encounter but without EDD 
          #{pg_status_encounter.encounter_id}, #{pg_status_encounter.obs_hash.inspect}"
          next
        end
        stream_start = Date.parse(due_date_text)
      end

      #community phones disallowed from voice delivery
      if encounter_data["TELEPHONE NUMBER TYPE "] == "COMMUNITY PHONE" && encounter_data["TYPE OF MESSAGE"] == "VOICE" 
        puts "#{skip_text} Voice enrollment for community phone"
        next
      end

      raise "Unknown language #{encounter_data["LANGUAGE PREFERENCE"]}" unless language = lang_to_lang[encounter_data["LANGUAGE PREFERENCE"]]
      raise "Unknown delivery type #{encounter_data["TYPE OF MESSAGE"]}" unless delivery_method = message_type_to_delivery[encounter_data["TYPE OF MESSAGE"]]



      if enrollment = Enrollment.active.where(:ext_user_id=>ext_user_id,:message_stream_id=>stream.id).first
        enrollment_ids_to_cancel.delete(enrollment.id)
      else
        enrollment = Enrollment.new
      end

      enrollment.attributes = {
        :first_name => first_name,
        :last_name => last_name,
        :phone_number => phone,
        :message_stream_id => stream.id,
        :language => language,
        :delivery_method => delivery_method,
        #          :stream_start => stream_start,
        # stream start for daily test streams
        :stream_start => Date.today - 1.day,

        :ext_user_id => ext_user_id,
        :status => "ACTIVE"
      }
      puts enrollment.inspect
      enrollment.save!  if ENV['HMS_SAVE_ENROLLMENTS']

    end

    if ENV['HMS_SAVE_ENROLLMENTS']
      Enrollment.find(enrollment_ids_to_cancel).each do |e|
        e.update_attributes(:status => Enrollment::CANCELLED)
      end
    end
    
  end

end

