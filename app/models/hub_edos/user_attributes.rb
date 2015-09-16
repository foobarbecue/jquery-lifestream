module HubEdos
  class UserAttributes < Proxy

    def initialize(options = {})
      super(Settings.hub_edos_proxy, options)
      initialize_mocks if @fake
    end

    def url
      ''
    end

    def json_filename
      'user_attributes.json'
    end

    def get_internal
      edo_feed = Student.new(user_id: @uid).get
      result = {}
      if (feed = edo_feed[:feed])
        edo = feed['student'] # TODO will have to dynamically switch student/person EDO somehow
        extract_ids(edo, result)
        extract_names(edo, result)
        extract_affiliations(edo, result)
        extract_emails(edo, result)
        extract_education_level(edo, result)
        extract_total_units(edo, result)
        extract_residency(edo, result)
        result[:statusCode] = 200
      else
        logger.error "Could not get Student EDO data for uid #{@uid}"
      end
      result
    end

    def extract_ids(edo, result)
      edo['identifiers'].each do |id|
        if id['type'] == 'CalNet UID'
          result[:ldap_uid] = id['id']
        elsif id['type'] == 'Student ID'
          result[:student_id] = id['id']
        end
      end
    end

    def extract_names(edo, result)
      edo['names'].each do |name|
        # use preferred name
        if name['type']['code'] == 'PRF'
          result[:first_name] = name['givenName']
          result[:last_name] = name['familyName']
          result[:person_name] = name['formattedName']
          break
        end
      end
    end

    def extract_affiliations(edo, result)
      result[:affiliations] = [] # TODO develop affiliations when we have more examples of different types
      edo['affiliations'].each do |affiliation|
        if affiliation['type']['code'] == 'UNDERGRAD' && affiliation['statusCode'] == 'ACT'
          result[:ug_grad_flag] = 'U'
        elsif affiliation['type']['code'] == 'GRAD' && affiliation['statusCode'] == 'ACT'
          result[:ug_grad_flag] = 'G'
        end
      end
    end

    def extract_emails(edo, result)
      edo['emails'].each do |email|
        if email['primary'] == true
          result[:email_address] = email['emailAddress']
        end
        if email['type']['code'] == 'CAMP'
          result[:official_bmail_address] = email['emailAddress']
        end
      end
    end

    def extract_education_level(edo, result)
      result[:educ_level] = edo['currentRegistration']['academicLevel']['level']['description']
    end

    def extract_total_units(edo, result)
      edo['currentRegistration']['termUnits'].each do |term_unit|
        if term_unit['type']['description'] == 'Total'
          result[:tot_enroll_unit] = term_unit['unitsEnrolled']
          break
        end
      end
    end

    def extract_residency(edo, result)
      if edo['residency']['official']['code'] == 'RES'
        result[:cal_residency_flag] = 'Y'
      else
        result[:cal_residency_flag] = 'N'
      end
    end
  end
end

