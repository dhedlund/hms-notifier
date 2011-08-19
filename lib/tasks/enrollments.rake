
namespace :enrollments do
  desc "test enrollments query"  
  task :query => :environment do
    logger = RAILS_DEFAULT_LOGGER

    class EncounterType < ActiveRecord::Base
      establish_connection Rails.configuration.database_configuration["openmrs"] 
      set_table_name :encounter_type
    end
    tips_etype = EncounterType.find_by_name("TIPS AND REMINDERS")
    pregnancy_etype = EncounterType.find_by_name("PREGNANCY STATUS")
    puts "#{tips_etype.name} type #{tips_etype.encounter_type_id}"
    puts "#{pregnancy_etype.name} type #{pregnancy_etype.encounter_type_id}"

    class Encounter < ActiveRecord::Base
      establish_connection Rails.configuration.database_configuration["openmrs"] 
      set_table_name :encounter
    end

    puts "#{Encounter.find_all_by_encounter_type(tips_etype.encounter_type_id).size} encounters"
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
    class Observation < ActiveRecord::Base
      establish_connection Rails.configuration.database_configuration["openmrs"] 
      set_table_name :obs
    end

    content_type_to_stream = {
      "CHILD" => "child",
      "GESTATION" => "pregnancy"
    }

    lang_to_lang = {
      "CHICHEWA" => "Default Language",
      "CHIYAO" => "Yao"
    } 
    message_type_to_delivery = {
      "SMS" => "SMS",
      "VOICE" => "IVR"
    }

    active_enrollments = Enrollment.active
    previous_active_ids = active_enrollments.map(&:id)

    #  desc "show verbose enrollment-related query results"
    #  task :show => :environment, :openmrs_models do
    all_tips_encounters=Encounter.find_all_by_encounter_type(tips_etype.encounter_type_id, :order=>"patient_id ASC, date_created ASC")
    all_tips_encounters_by_patient= all_tips_encounters.group_by(&:patient_id)
    puts "#{all_tips_encounters_by_patient.size} patients"
    all_tips_encounters_by_patient.each do |patient_id, encounters|
      patient_name = PersonName.find_by_person_id(patient_id)
      first_name = patient_name.given_name
      last_name = patient_name.family_name
      puts "#{first_name} #{last_name} #{patient_id} #{encounters.size}"
      last_enc = encounters.last
      #these obs only use value_text or value_coded, which refers to a concept
      obs_selects = Observation.find_by_sql("
      SELECT oname.name, ifnull(obs.value_text, vname.name) AS val
      FROM obs 
      JOIN concept_name oname ON (oname.concept_id = obs.concept_id)
      LEFT JOIN concept_name vname ON (vname.concept_id = obs.value_coded)
      WHERE obs.encounter_id = #{last_enc.encounter_id}
      ")
      encounter_data = {}
      obs_selects.each do |o| 
        encounter_data[o.name] = o.val
        raise "Null observation value:  #{obs_selects.inspect}" if o.val.nil?
      end

      puts " #{last_enc.date_created}  #{last_enc.encounter_id}: #{encounter_data.inspect}"

      phone = encounter_data["PHONE NUMBER"].gsub(" ","")

      national_id = Patient.find_by_sql("SELECT identifier FROM patient_identifier 
      WHERE patient_id = #{patient_id} AND identifier_type = #{national_id_type_id}").first.identifier
      ivr_id = Patient.find_by_sql("SELECT identifier FROM patient_identifier 
      WHERE patient_id = #{patient_id} AND identifier_type = #{ivr_id_type_id}").first.identifier

      ext_user_id = "#{ivr_id}/#{national_id}"
      person_log_summary = "#{first_name} #{last_name} #{phone} #{ext_user_id}"

      next unless encounter_data["ON TIPS AND REMINDERS PROGRAM"] == "YES"
      #some data checking.  could put a check that the full list of obs is present, and 
      #even make an hash of arrays of acceptable values, perhaps even skip values (ignored, but not an error)
      unless stream_name = content_type_to_stream[encounter_data["TYPE OF MESSAGE CONTENT"]]
        puts "Unsupported message type #{encounter_data["TYPE OF MESSAGE CONTENT"]} for #{person_log_summary}"
        next
      end
      stream = MessageStream.find_by_name(stream_name) 
      raise "stream not found for name #{stream_name}" if stream.nil?
      if stream_name=="child"
        stream_start = Person.find_by_person_id(patient_id).birthdate
      elsif stream_name=="pregnancy"
        stream_start = nil
      end

        #community phones disallowed from voice delivery
        if encounter_data["TELEPHONE NUMBER TYPE "] == "COMMUNITY PHONE" && encounter_data["TYPE OF MESSAGE"] == "VOICE" 
          puts "Skipping Voice enrollment for community phone #{person_summary}"
          next
        end

        raise "Unknown language #{encounter_data["LANGUAGE PREFERENCE"]}" unless language = lang_to_lang[encounter_data["LANGUAGE PREFERENCE"]]
        raise "Unknown delivery type #{encounter_data["TYPE OF MESSAGE"]}" unless delivery_method = message_type_to_delivery[encounter_data["TYPE OF MESSAGE"]]



        if enrollment = active_enrollments.where(:ext_user_id=>ext_user_id,:message_stream_id=>stream.id).first
          previous_active_enrollment_ids.delete{|eid| eid==enrollment.id}
        else
          enrollment = Enrollment.new
          # stream start for testing
          stream_start = Date.today - 1.day
        end

        enrollment.attributes = {
          :first_name => first_name,
          :last_name => last_name,
          :phone_number => phone,
          :message_stream => stream,
          :language => language,
          :delivery_method => delivery_method,
#          :stream_start => stream_start,
          :ext_user_id => ext_user_id,
          :status => "ACTIVE"
        }
        puts enrollment.inspect
        #      enrollment.save!



      end

    end


  end

