require_relative 'utils/utils.rb'
require 'colorize'
require 'fileutils'

Encoding::default_external = Encoding::UTF_8
# Encoding::default_external = 'cp1251'

class EchampsUploader
  # EchampsUploader << self
  #
  @sport_kind_list = Utils.symbolize_keys(
      Utils.read_csv_file('I:/dev_temp/zoon/upload/unknown_sportkindы-VG.csv'))

  def self.iterate_users
    begin
      require './models/zoon_model_2.rb'
      # get users as json
      users = Coach.all.as_json
      json_file = []
      i = 0
      users.each {|user|
        user = user.symbolize_keys
        puts "#{i} из #{users.count} #{user[:id]}: #{user[:name]}"
        i += 1
        user.merge!(country: 'Россия', region: 'Москва', city: 'Москва', user_type: 'coach', position_id: 2)
        user[:name] = Utils.titleize_fio(user[:name])
        fio = split_fio_str(user[:name])
        next if fio.nil?
        user.merge!(split_fio_str(user[:name]))
        user = Utils.hash_replace_value(user, '-', nil)
        user[:specialization] = Utils.normalize_string(user[:specialization])
        user[:education] = Utils.normalize_string(user[:education])
        user[:experience] = Utils.normalize_string(user[:experience])
        user[:info] = Utils.normalize_string(user[:info])
        # create list of unknown sport kinds
        # check_sport_kind_exist(user)
        user[:org] = get_zoon_organization_by_id_as_hash(user[:gym_id])
        # user[:roles] = get_roles(user[:specialty])
        move_users_from_hash(user)
        # json_file.append(create_json_element(user))
        # return if i == 1
      }
      Utils.create_json_from_hash(json_file, 'I:/dev_temp/zoon/echamps_upload.json')
      puts 'done'
    rescue => ex
      puts "#{ex.full_message}"
      EchampsBase.close_connection
    end
  end

  def self.create_json_element(user)
    user_profile = Hash.new
    org = Hash.new

    city = {country_id: 191, country_region_id: 2847, city_id: 3820210}
    if user[:org]
      org = {id: nil, name: user[:org][:title],
             organization_type_id: nil,
             street: user[:org][:address], status: true
      }
      org.merge!(city)
    end
    user_profile.merge!(city)


    specialization = user[:specialization].nil? ?
                         '' : "<strong>Специализация:</strong><br>#{user[:specialization]}<br><br>"
    education = user[:education].nil? ?
                    '' : "<strong>Образование:</strong><br>#{user[:education]}<br><br>"
    experience = user[:experience].nil? ?
                     '' : "<strong>Опыт:</strong><br>#{user[:experience]}<br><br>"
    info = user[:info].nil? ?
               '' : "<strong>Информация:</strong><br>#{user[:info]}<br>"
    user_profile[:about] = "#{specialization}#{education}#{experience}#{info}"


    user_profile.merge!({user_id: nil, username: nil, username_canonical: nil,
                         email: nil, email_canonical: nil, roles: 'a:0:{}', is_cms_user: false,
                         enabled: true, password: nil, status: true, user_agreement: true,
                         gdpr_argreement: true, is_created_user: true,
                         user_profile_id: nil, first_name: user[:first_name],
                         last_name: user[:last_name], middle_name: user[:middle_name],
                         birthday: nil, gender: nil, phone: user[:phone], user_type: 'coach',
                         image_name: nil, year_of_birth: nil, image_original_name: user[:photo],
                         source_link: user[:source_url],
                         user_org_id: nil, is_current: true, position_id: 2,
                         user_profile_role_id: nil, sport_kind_id: nil, is_main: true})

    user_profile[:org] = org
    user_profile[:user_roles] = []
    if !user[:specialty].nil? and user[:specialty].include?(',')
      user[:specialty].split(', ').each {|role|
        user_profile[:user_roles].append(
            {role_id: nil, sport_kind: nil, discipline_id: nil,
             coach_specialization_id: nil, coach_category_id: nil,
             role: role})}
    else
      user_profile[:user_roles].append(
          {role_id: nil, sport_kind: nil, discipline_id: nil,
           coach_specialization_id: nil, coach_category_id: nil,
           role: user[:specialty]})
    end

    return user_profile
    puts 'Done'
  end

  def self.split_fio_str(fio_str)
    user_name = Hash.new
    names = fio_str.split

    case names.count
    when 3
      user_name[:first_name] = names[0]
      user_name[:middle_name] = names[1]
      user_name[:last_name] = names[2]
    when 2
      user_name[:first_name] = names[0]
      user_name[:last_name] = names[1]
    when 1
      # puts "INFO. exist only name #{user[:name]}"
      return nil
    when 4
      user_name[:first_name] = names[0]
      user_name[:middle_name] = names[1]
      user_name[:last_name] = "#{names[2]} #{names[3]}"
    else
      puts "ERROR. #{fio_str}".red
      return nil
    end
    return user_name
  end

  def self.gen_user
    user = {country: 'Россия', region: 'Москва', city: 'Москва',
            photo: 'aaron_virobyan.jpg', name: 'Аарон Виробян',
            phone: '+7 (495) 106-25-93',
            specialty: 'спортивная гимнастика',
            info: 'ИНСТРУКТОР ЗАЛА ЕДИНОБОРСТВ. Тренер: Силовая Гимнастика Workout Спортивные достижения: Зафиксировал 7 мировых рекордов Попал в книгу рекордов Армении Мастер спорта по паурлифтингу (жим лежа)Мастер спорта по стритлифтингу (подтягивания и отжимание от брусьев с отягощением) Мастер спорта международного класса по стритворкауту Тренировки: На моих тренировках я учу акробатическим упражнениям на турниках, кольцах, гимнастическим стенкам, учу правильно растягиваться и садится на шпагат. Во время тренировочного процесса укрепляется тело, сухожилия, мышечный корсет. В зависимости от ваших целей готовлю к соревнованиям от местного уровня до международного. Делаю ваше тело атлетическим красивым и подтянутым. Моя мотивация даст вам отличный результат! Жду на тренировках J',
            specialization: 'силовой тренинг',
            education: 'Государственный Армянский Институт физической культуры.',
            experience: 'Общая практика:Более 5 лет работаю с профессиональными спортсменами России, Армении и спортсменами Международного класса.Более 3-х лет работаю с детьми, подростками в секциях спорта, готовлю к спортивным соревнованиям и мероприятиям.',
            source_url: 'https://zoon.ru/msk/p-trener/aaron_virobyan/'}
    return user
  end

  def self.move_users_from_hash(user)
    # city_id=3747056
    # country_id=191
    # country_region_id=2847

    user_profile = Hash.new

    user_profile[:first_name] = user[:first_name]
    user_profile[:middle_name] = user[:middle_name]
    user_profile[:last_name] = user[:last_name]

    # country_id = User.get_country_id(user[:country])
    # region_id = User.get_region_id(user[:region])
    # city = User.get_city_id(Utils.titleize(user[:city]))
    city = {country_id: 191, country_region_id: 2847, city_id: 3820210}
    user_profile.merge!(city)

    if user[:org]
      org = user[:org]
      org.merge!(city)
      org[:organization_type_id] = nil

      # check_org_by_list(org[:organization_type])

      # проверяем организацию в таблице организации
      org_db = Organization.find_by('lower(name) LIKE ?', "#{org[:title].downcase}%")
      if !org_db
        org_db = create_organization_db(org)
        # else
        # puts "Organization id:#{org_db.id} name:#{org_db.name} already exists in DB"
      end
      user_profile[:organization_id] = org_db.id
    else
      user_profile[:organization_id] = nil
    end

    #
    # проверяем пользователя в таблице профиля по имя фамилия город
    user_profile_db = UserProfile.find_by('first_name LIKE ? AND last_name LIKE ? AND city_id = ?',
                                          Utils.titleize(user_profile[:first_name]),
                                          Utils.titleize(user_profile[:last_name]),
                                          user_profile[:city_id])

    # если не нашли, то просто по имени и фамилии,
    user_profile_db = UserProfile.find_by('first_name LIKE ? AND last_name LIKE ?',
                                          Utils.titleize(user_profile[:first_name]),
                                          Utils.titleize(user_profile[:last_name])
    ) if user_profile_db.nil?

    # если нашли, то проверяем роль и результаты, если нет, то создаем
    if !user_profile_db
      # если не нашли, то создаем пользователя
      user_db = create_user_db(user_profile)
      user_profile[:user_id] = user_db.id
      user_profile[:email] = user_db.email

      user_profile[:image_original_name] = user[:photo]

      if !user[:photo].nil? and user[:photo].include?('.')
        photo = user[:photo].split('.')
        user_profile[:image_name] = "#{Utils.gen_md5(photo[0])}.#{photo[-1]}"
      else
        user_profile[:image_name] = nil
      end


      # src = "I:/dev_temp/zoon/photo/#{user_profile[:image_original_name]}"
      # dst = "I:/dev_temp/zoon/upload_photo/#{user_profile[:image_name]}"
      # FileUtils.cp(src, dst)

      user_profile[:birthday] = nil
      user_profile[:gender] = nil
      user_profile[:phone] = user[:phone]
      user_profile[:user_type] = user[:user_type]
      user_profile[:year_of_birth] = nil

      specialization = user[:specialization].nil? ?
                           '' : "<strong>Специализация:</strong><br>#{user[:specialization]}<br><br>"
      education = user[:education].nil? ?
                      '' : "<strong>Образование:</strong><br>#{user[:education]}<br><br>"
      experience = user[:experience].nil? ?
                       '' : "<strong>Опыт:</strong><br>#{user[:experience]}<br><br>"
      info = user[:info].nil? ?
                 '' : "<strong>Информация:</strong><br>#{user[:info]}<br>"

      user_profile[:about] = "#{specialization}#{education}#{experience}#{info}"
      user_profile[:source_link] = user[:source_url]

      # если не нашли, то создаем профиль
      user_profile_db = create_user_profile_db(user_profile)
      user_profile[:id] = user_profile_db.id
    else
      user_profile.merge!(user_profile_db.as_json.symbolize_keys)
    end

    #
    # создаем связь user - organization
    #
    user_profile[:position_id] = user[:position_id]
    if user_profile[:organization_id]
      user_org_db = create_user_organization_db(user_profile)
      user_profile[:user_organization_id] = user_org_db.id
    end

    #
    # проверяем существование роли
    #
    user_profile[:roles] = user[:roles]

    if !user_profile[:roles].nil?
      user_profile[:roles].map {|role|
        user_profile_role_db = UserProfileRole.find_by(
            user_profile_id: user_profile[:id],
            type: user_profile[:user_type],
            sport_kind_id: role[:sport_kind_id],
            coach_specialization_id: role[:coach_specialization_id],
            coach_category_id: role[:coach_category_id]
        )
        if user_profile_role_db.nil?
          # создаем роль
          user_profile_role_db = create_user_profile_role_db(user_profile, role)
        end
        role[:id] = user_profile_role_db.id
      }
    end
    # проверяем существование достижения
    # todo создать проверку наличия достижения
    # создаем достижения
    # user_achievement_db = create_user_achievement_db(user_profile)
    # user_profile[:user_achievement_id] = user_achievement_db.id

    puts "Created USER id:#{user_profile[:id]} org_id:#{user_profile[:organization_id]}"
  end

  def self.upload_echamps_data_from_json()
    begin

      # city_id=3747056
      # country_id=191
      # country_region_id=2847

      user_profiles = Utils.symbolize_keys(Utils.read_json_file('I:/dev_temp/zoon/echamps_upload.json'))
      i = 0
      require './models/echamps_model.rb'
      user_profiles.each {|user_profile|

        if user_profile[:org]
          # проверяем организацию в таблице организации
          puts "#{user_profile[:org][:name].downcase}%"
          org_db = Organization.find_by('lower(name) LIKE ?', "#{user_profile[:org][:name].downcase}%")
          if !org_db
            org_db = create_organization_db(user_profile[:org])
            # else
            # puts "Organization id:#{org_db.id} name:#{org_db.name} already exists in DB"
          end
          user_profile[:organization_id] = org_db.id
        else
          user_profile[:organization_id] = nil
        end
        i += 1
        break if i == 11
        next

        #
        # проверяем пользователя в таблице профиля по имя фамилия город
        user_profile_db = UserProfile.find_by('first_name LIKE ? AND last_name LIKE ? AND city_id = ?',
                                              user_profile[:first_name],
                                              user_profile[:last_name],
                                              user_profile[:city_id])

        # если не нашли, то просто по имени и фамилии,
        user_profile_db = UserProfile.find_by('first_name LIKE ? AND last_name LIKE ?',
                                              user_profile[:first_name],
                                              user_profile[:last_name]
        ) if user_profile_db.nil?

        # если нашли, то проверяем роль и результаты, если нет, то создаем
        if !user_profile_db
          # если не нашли, то создаем пользователя
          user_db = create_user_db(user_profile)
          user_profile[:user_id] = user_db.id
          user_profile[:email] = user_db.email

          user_profile[:image_original_name] = user[:photo]

          if !user[:photo].nil? and user[:photo].include?('.')
            photo = user[:photo].split('.')
            user_profile[:image_name] = "#{Utils.gen_md5(photo[0])}.#{photo[-1]}"
          else
            user_profile[:image_name] = nil
          end


          # src = "I:/dev_temp/zoon/photo/#{user_profile[:image_original_name]}"
          # dst = "I:/dev_temp/zoon/upload_photo/#{user_profile[:image_name]}"
          # FileUtils.cp(src, dst)

          user_profile[:birthday] = nil
          user_profile[:gender] = nil
          user_profile[:phone] = user[:phone]
          user_profile[:user_type] = user[:user_type]
          user_profile[:year_of_birth] = nil

          specialization = user[:specialization].nil? ?
                               '' : "<strong>Специализация:</strong><br>#{user[:specialization]}<br><br>"
          education = user[:education].nil? ?
                          '' : "<strong>Образование:</strong><br>#{user[:education]}<br><br>"
          experience = user[:experience].nil? ?
                           '' : "<strong>Опыт:</strong><br>#{user[:experience]}<br><br>"
          info = user[:info].nil? ?
                     '' : "<strong>Информация:</strong><br>#{user[:info]}<br>"

          user_profile[:about] = "#{specialization}#{education}#{experience}#{info}"
          user_profile[:source_link] = user[:source_url]

          # если не нашли, то создаем профиль
          user_profile_db = create_user_profile_db(user_profile)
          user_profile[:id] = user_profile_db.id
        else
          user_profile.merge!(user_profile_db.as_json.symbolize_keys)
        end

        #
        # создаем связь user - organization
        #
        user_profile[:position_id] = user[:position_id]
        if user_profile[:organization_id]
          user_org_db = create_user_organization_db(user_profile)
          user_profile[:user_organization_id] = user_org_db.id
        end

        #
        # проверяем существование роли
        #
        user_profile[:roles] = user[:roles]

        # if !user_profile[:roles].nil?
        #   user_profile[:roles].map {|role|
        #     user_profile_role_db = UserProfileRole.find_by(
        #         user_profile_id: user_profile[:id],
        #         type: user_profile[:user_type],
        #         sport_kind_id: role[:sport_kind_id],
        #         coach_specialization_id: role[:coach_specialization_id],
        #         coach_category_id: role[:coach_category_id]
        #     )
        #     if user_profile_role_db.nil?
        #       # создаем роль
        #       user_profile_role_db = create_user_profile_role_db(user_profile, role)
        #     end
        #     role[:id] = user_profile_role_db.id
        #   }
        # end
        # проверяем существование достижения
        # todo создать проверку наличия достижения
        # создаем достижения
        # user_achievement_db = create_user_achievement_db(user_profile)
        # user_profile[:user_achievement_id] = user_achievement_db.id

        puts "Created USER id:#{user_profile[:id]} org_id:#{user_profile[:organization_id]}"

      }
    rescue => ex
      puts ex.full_message
      EchampsBase.close_connection
    end
  end

  def self.get_roles(user_roles)
    sport_kinds_arr = []

    if !user_roles.nil? and user_roles.include?(',')
      sport_kinds_src = user_roles.split(', ')

      sport_kinds_src.each {|sport_kind_name|
        sport_kind_id = UserProfile.get_sport_kind_id(sport_kind_name)
        res = []
        if !sport_kind_id
          res = @sport_kind_list.select {|elem| elem[:sport_kind_name] == "#{sport_kind_name}"}
        else
          res = {sport_kind_id: sport_kind_id, discipline_id: nil,
                 coach_specialization_id: nil, coach_category_id: nil}
        end
        sport_kinds_arr.append(res) if !res.empty?
      }
    elsif !user_roles.nil?
      sport_kind_id = UserProfile.get_sport_kind_id(user_roles)
      res = []
      if !sport_kind_id
        res = @sport_kind_list.select {|elem| elem[:sport_kind_name] == "#{user_roles}"}
      else
        res = {sport_kind_id: sport_kind_id, discipline_id: nil,
               coach_specialization_id: nil, coach_category_id: nil}
      end
      sport_kinds_arr.append(res) if !res.empty?
    else
      return nil
    end
    return sport_kinds_arr
  end

  def self.create_user_achievement_db(user_profile)
    begin
      user_profile[:user_achievement_id] = UserAchievement.next_id_sequence
      event = user_profile[:event]
      # todo need finish method
      user_achievement_db = UserAchievement.create(
          id: user_profile[:user_achievement_id],
          sport_kind_id: user_profile[:sport_kind_id],
          sport_kind_discipline_id: sport_kind_discipline_id?,
          country_region_id: event[:country_region_id],
          country_id: event[:country_id], city_id: event[:city_id],
          event_id: event[:id], user_profile_id: user_profile[:id],
          event_date: event[:event_date], role: user_profile[:user_type]
      )
      return user_achievement_db
    rescue => ex
      rollback(user_profile)
      puts ex.full_message.red
      exit(-1)
    end
  end

  def self.create_user_profile_role_db1(user_profile, role)
    begin
      role[:user_profile_id] = user_profile[:id]
      role[:id] = UserProfileRole.next_id_sequence
      user_profile_role_db = UserProfileRole.create(
          id: role[:id], user_profile_id: user_profile[:id],
          sport_kind_id: role[:sport_kind_id],
          organization_id: user_profile[:organization_id],
          type: user_profile[:user_type],
          is_main: true
      )
      return user_profile_role_db
    rescue => ex
      my_rollback(role, :user_profile_role)
      puts ex.full_message.red
      exit(-1)
    end
  end

  def self.create_user_profile_db(user_profile)
    begin
      user_profile[:id] = UserProfile.next_id_sequence
      user_profile_db = UserProfile.create(
          id: user_profile[:id], country_id: user_profile[:country_id],
          city_id: user_profile[:city_id], user_id: user_profile[:user_id],
          first_name: user_profile[:first_name], last_name: user_profile[:last_name],
          middle_name: user_profile[:middle_name], birthday: user_profile[:birthday],
          gender: user_profile[:gender], email: user_profile[:email],
          phone: user_profile[:phone], user_type: user_profile[:user_type],
          image_name: user_profile[:image_name], year_of_birth: user_profile[:year_of_birth],
          image_original_name: user_profile[:image_original_name],
          about: user_profile[:about], country_region_id: user_profile[:country_region_id],
          source_link: user_profile[:source_link]
      )
      return user_profile_db
    rescue => ex
      my_rollback(user_profile, :user_profile)
      puts ex.full_message.red
      exit(-1)
    end
  end

  def self.create_user_organization_db(user_profile)
    begin
      user_org_db = UserOrganization.find_by(user_profile_id: user_profile[:id],
                                             organization_id: user_profile[:organization_id],
                                             position_id: user_profile[:position_id])
      return user_org_db if !user_org_db.nil?
      user_profile[:user_organization_id] = UserOrganization.next_id_sequence
      user_org_db = UserOrganization.create(
          id: user_profile[:user_organization_id],
          user_profile_id: user_profile[:id],
          organization_id: user_profile[:organization_id],
          is_current: true,
          position_id: user_profile[:position_id]
      )
      return user_org_db
    rescue => ex
      my_rollback(user_profile, :user_organization)
      puts ex.full_message.red
      exit(-1)
    end
  end

  def self.create_user_db(user_profile)
    begin
      user_profile[:user_id] = User.next_id_sequence
      user_profile[:email] = "#{user_profile[:user_id]}@e-champs.com"
      password = Utils.gen_md5(user_profile[:email])
      user_db = User.create(
          id: user_profile[:user_id], username: user_profile[:email], username_canonical: user_profile[:email],
          email: user_profile[:email], email_canonical: nil, roles: user_profile[:roles], is_cms_user: false,
          enabled: true, password: password, status: true, user_agreement: true,
          gdpr_argreement: true, is_created_user: true
      )
      return user_db
    rescue => ex
      my_rollback(user_profile, :user)
      puts ex.full_message.red
      exit(-1)
    end
  end

  def self.create_organization_db(org)
    begin
      org[:id] = Organization.next_id_sequence
      org_db = Organization.create(
          id: org[:id], country_id: org[:country_id], country_region_id: org[:country_region_id],
          city_id: org[:city_id], organization_type_id: org[:organization_type_id],
          name: org[:name], street: org[:street], status: true
      )
      return org_db
    rescue => ex
      my_rollback(org, :organization)
      puts ex.full_message.red
      exit(-1)
    end
  end

  def self.get_zoon_organization_by_id_as_hash(gym_id)
    org = Gym.where(id: gym_id).first.as_json
    return nil if org.nil?
    org = org.symbolize_keys
    org.merge!(country: 'Россия', region: 'Москва', city: 'Москва')
    org[:address] = Utils.normalize_string(org[:address])
    return org
  end

  def self.my_rollback(object, rollback_type)
    puts rollback_type
    begin
      case rollback_type
      when :organization
        Organization.alter_sequence_id(object[:id])
        Organization.destroy(object[:id])
      when :user
        User.alter_sequence_id(object[:user_id])
        User.destroy(object[:user_id])
      when :user_profile
        UserProfile.destroy(object[:id])
        UserProfile.alter_sequence_id(object[:id])
        User.destroy(object[:user_id])
        User.alter_sequence_id(object[:user_id])
      when :user_organization
        UserOrganization.destroy(object[:user_organization_id])
        UserOrganization.alter_sequence_id(object[:user_organization_id])
      when :user_profile_role
        # UserProfile.destroy(object[:user_profile_id])
        # UserProfile.alter_sequence_id(object[:user_profile_id])
        # User.destroy(object[:user_profile_id])
        # User.alter_sequence_id(object[:user_profile_id])
        UserProfileRole.destroy(object[:id])
        UserProfileRole.alter_sequence_id(object[:id])
      when :user_achievement
        # UserProfile.destroy(object[:id])
        # UserProfile.alter_sequence_id(object[:id])
        # User.destroy(object[:user_id])
        # User.alter_sequence_id(object[:user_id])
        # UserProfileRole.alter_sequence_id(id)
        # UserProfileRole.destroy(object[:user_profile_role_id])
        UserAchievement.alter_sequence_id(object[:user_achievement_id])
        UserAchievement.destroy(object[:user_achievement_id])
      else
        puts 'something wrong in rollback'
      end
    rescue => ex
      puts ex.full_message
    end
    EchampsBase.close_connection
  end

  def self.check_sport_kind_exist(user)
    @unknown_sportkind = []
    user_specialty = user[:specialty]

    if user_specialty.include?(',')
      sportkindes = user_specialty.split(', ')
      sportkindes.each {|sport_kind_name|
        sportkind_id = UserProfile.get_sport_kind_id(sport_kind_name)

        if !sportkind_id
          # begin
          hash_str = "sportkind_name;#{sport_kind_name};id;-"
          @unknown_sportkind.to_a.append(Hash[*hash_str.split(';')]) if !hash_str.empty?
          # rescue => ex
          #   puts "[DEBUG] #{hash_str}"
          #   puts "\t[ERR] #{ex.backtrace}"
          # end
        end
      }
    else
      sportkind_id = UserProfile.get_sport_kind_id(user_specialty)

      if !sportkind_id
        # begin
        hash_str = "sportkind_name;#{sport_kind_name};id;-"
        @unknown_sportkind.to_a.append(Hash[*hash_str.split(';')]) if !hash_str.empty?
        # rescue => ex
        #   puts "[DEBUG] #{hash_str}"
        #   puts "\t[ERR] #{ex.backtrace}"
        # end
      end
    end
    Utils.create_csv_from_hash_with_headers(@unknown_sportkind,
                                            'I:/dev_temp/zoon/upload/unknown_sportkind.csv')
  end

  def self.add_organization_from_hash(org)
    # org = {
    #     country: 'Россия', region: 'Москва', city: 'Москва',
    #     organization_type: 'Sport Club', title: 'Чемпион',
    #     address: 'Московская область, Домодедово, Советская улица, 28, ФОК "Фокус"'
    # }

    org[:country_id] = Organization.get_country_id(org[:country])

    org[:region_id] = Organization.get_region_id(org[:region])

    org[:city_id] = Organization.get_city_id(org[:city])

    org[:organization_type_id] = Organization.get_org_type_id(org[:organization_type])

    check_org_by_list(org[:organization_type])

    org_db = Organization.find_by('lower(name) LIKE ?', org[:title].downcase)
    if !org_db
      # puts "CREATE Organization(id: #{org_id}, country_id: #{country_id},
      #       country_region_id: #{region_id}, city_id: #{city_id},
      #       organization_type_id: #{organization_type_id},
      #       name: #{org[:title]}, street: #{org[:address]})"
      create_organization_db(org)
    else
      puts "Organization id:#{org_db.id} name:#{org_db.name} already exists in DB"
    end
  end

  def self.iterate_organizations
    # get organization as json
    require './models/zoon_model.rb'
    orgs = Gym.all.as_json
    require './models/echamps_model.rb'
    orgs.each {|org|

      org = org.symbolize_keys
      if !(org[:title] == '-')
        org[:address] = Utils.normalize_string(org[:address])
        org.merge!(country: 'Россия', region: 'Москва', city: 'Москва', organization_type: 'Sport Club')
        add_organization_from_hash(org)
      else
        puts "#{org[:title]}=='-'"
      end
    }
  end

  def self.convert_photo_to_site(src_path)
    dst_path = "I:/dev_temp/zoon/upload_photo/"
    Dir.glob("#{src_path}*").each do |filename|
      photo = File.basename(filename).split('.')
      new_name = "#{Utils.gen_md5(photo[0])}.#{photo[-1]}"
      dest_folder = "#{dst_path}#{new_name}"
      FileUtils.cp(filename, dest_folder)
    end
  end

  # require './models/echamps_model.rb'
  # user_profile_role_db = UserProfileRole.find_by(
  #     user_profile_id: 25,
  #     sport_kind_id: 102,
  #     coach_specialization_id: nil,
  #     coach_category_id: nil,
  #     type: 'coach'
  # )
  # begin
  #   # role[:id] = UserProfileRole.next_id_sequence
  #   user_profile_role_db = UserProfileRole.create(
  #       id: 10295,
  #       user_profile_id: 9473,
  #       sport_kind_id: 102,
  #       type: 'coach',
  #       is_main: true
  #   )
  #   puts user_profile_role_db
  # rescue => ex
  #   # my_rollback(role, :user_profile_role)
  #   puts ex.full_message.red
  #   exit(-1)
  # end
  # puts 1


  # convert_photo_to_site("I:/dev_temp/zoon/photo/")

  upload_echamps_data_from_json
  # iterate_users
  # EchampsBase.close_connection
  puts 'end'
end