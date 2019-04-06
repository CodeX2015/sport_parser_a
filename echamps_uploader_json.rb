require_relative 'utils/utils.rb'
require 'colorize'
require 'fileutils'
# require 'activerecord-import'
require 'benchmark'

Encoding::default_external = Encoding::UTF_8
# Encoding::default_external = 'cp1251'

class EchampsJsonUploader
  # EchampsUploader << self
  #

  def self.normalise_user(user)
    case @src_type
    when :zoon
      puts 'zoon'
    when :sportcubes
      if !user[:city].nil?
        city = EchampsBase.get_city_id(user[:city])
        user.merge!(city)
      end
      user[:events].map {|event|
        event[:sport_kind_discipline_id] = Event.get_discipline_kind_id(event[:sport_kind_id],
                                                                        event[:discipline_kind])
        event[:rank_id] = Rank.get_rank_id(user[:rank]) if !event[:rank].nil?
        city = EchampsBase.get_city_id(event[:city])
        event.merge!(city)
      }
    when :nastart
      user[:name] = "#{user[:name].split[-1]} #{user[:name].split[0]}"

    end
  end

  def self.upload_echamps_db_from_json()
    require './models/echamps_model_new.rb'
    i = 1
    err_i = 1
    elapsed = 0
    json_file = []
    @users.each {|user|
      puts "#{i} из #{@users.count} #{user[:last_name]}"
      is_create = false
      loop do
        begin
          # user[:image_name] = rename_photo(user[:image_original_name]) if !user[:image_original_name].nil?
          normalise_user(user)
          time = Benchmark.measure {create_row(user)}
          elapsed += time.real
          puts "elapsed: #{time.real}s, total: #{elapsed / 60}m".blue
          i += 1
          is_create = true
          err_i = 1
        rescue => ex
          puts ex.message
          err_i += 1
          EchampsBase.reconnect
          EchampsBase.reset_statement
          sleep(2)
        end
        break if is_create
        abort('it\'s to many errors') if err_i > 10
      end
      # json_file.append(create_json_element(user))
      return if i == 10
    }
    # Utils.create_json_from_hash(json_file, @json_file_path)
  end

  def self.rename_photo(photo_name)
    require 'fileutils'
    begin
      filename = "#{@user_photo_path}in/#{photo_name}"
      return nil if !File.exists?(filename)
      photo = File.basename(filename).split('.')
      new_name = "#{Utils.gen_md5(photo[0])}.#{photo[-1]}"
      dest_folder = "#{@user_photo_path}out/#{new_name}"
      # File.rename(filename, dest_folder)
      FileUtils.cp(filename, dest_folder)
      return new_name
    rescue => ex
      puts ex.full_message
    end
  end

  def self.create_row(user)
    # city_name=Moscow
    # city_id=3747056
    # country_id=191
    # country_region_id=2847

    #
    # если нашли, то проверяем роль и результаты, если нет, то создаем
    #
    user_profile_db = UserProfile.create_user_profile_db(user)
    user.merge!(user_profile_db.as_json.compact.symbolize_keys)
    puts "user(#{user[:user_id]}) and user_profile(#{user[:id]}) created".blue

    #
    # доавляем организации
    #
    if user[:org] and !user[:org].empty?
      # puts "#{user[:org][:name].downcase}%"
      org_db = Organization.create_organization_db(user[:org])
      user[:organization_id] = org_db.id
    else
      user[:organization_id] = nil
    end

    #
    # создаем связь user - organization
    #
    if user[:organization_id]
      user_org_db = UserOrganization.create_user_organization_db(user)
      user[:user_organization_id] = user_org_db.id
    end

    #
    # проверяем существование роли
    #
    if !user[:user_roles].nil?
      user[:user_roles].map {|role|
        update_sport_kind_data(role)
        user_profile_role_db = UserProfileRole.create_user_profile_role_db(user, role)
        role[:role_id] = user_profile_role_db.id
        # puts "event(#{event[:id]}) and achievement(#{event[:achievement_id]}) created".blue
      }
    end

    #
    # проверяем существование результата и соревнования
    #
    if !user[:events].nil?
      user[:events].map {|event|

        # создаем мероприятие
        event_db = Event.create_event_db(event)
        event[:id] = event_db.id

        # создаем роль
        role = {sport_kind_id: event[:sport_kind_id], rank_id: event[:rank_id]}
        user_profile_role_db = UserProfileRole.create_user_profile_role_db(user, role)
        event[:role_id] = user_profile_role_db.id

        # создаем достижение
        user_achievement_db = UserAchievement.create_user_achievement_db(user, event)
        event[:achievement_id] = user_achievement_db.id
        puts "event(#{event[:id]}) and achievement(#{event[:achievement_id]}) created".blue
      }
    end

    puts "Created USER id:#{user[:id]} org_id:#{user[:organization_id]}"
  end

  def self.update_sport_kind_data(user_role)
    if !user_role[:sport_kind_name].nil? and !user_role[:sport_kind_name].empty?
      sport_kind_id = UserProfile.get_sport_kind_id(user_role[:sport_kind_name])
      if !sport_kind_id
        res = @sport_kind_list.select {|elem| elem[:sport_kind_name] == "#{user_role[:sport_kind_name]}"}
        user_role.merge!(res[0]) if !res.empty?
      else
        user_role[:sport_kind_id] = sport_kind_id
      end
    end
  end

  def self.load_users()
    begin
      @sport_kind_list = Utils.symbolize_keys(
          Utils.read_csv_file('I:/dev_temp/zoon/upload/unknown_sportkindы-VG.csv'))
      case @src_type
      when :zoon
        @json_file_path = 'I:/dev_temp/zoon/echamps_zoon_upload_test.json'
        # @json_file_path ='I:/dev_temp/zoon/echamps_upload_2.json'
      when :sportcubes
        @json_file_path = 'I:/dev_temp/sportcubes/echamps_sportcubes_upload_demo.json'
        @user_photo_path = 'I:/dev_temp/sportcubes/photo/'
      when :nastart
        @json_file_path = 'I:/dev_temp/nastart/echamps_nastart_upload_test.json'
        @user_photo_path = 'I:/dev_temp/nastart/photo/'
      end
      @users = Utils.symbolize_keys(Utils.read_json_file(@json_file_path))
    rescue => ex
      puts ex.full_message
    end
  end

  @src_type = :sportcubes
  load_users()
  upload_echamps_db_from_json
  puts 'end'
end