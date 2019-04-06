require_relative 'utils/utils.rb'
require 'colorize'
require 'fileutils'

Encoding::default_external = Encoding::UTF_8
# Encoding::default_external = 'cp1251'

class DbJsonCreator

  def self.iterate_users()
    begin
      json_file = []
      i = 1
      @users.each {|user|
        user = user.symbolize_keys
        puts "#{i} из #{@users.count} #{user[:id]}: #{user[:name]}"
        i += 1
        normalise_user(user)
        user[:name] = Utils.titleize_fio(user[:name])
        fio = split_fio_str(user[:name])
        next if fio.nil?
        user.merge!(fio)
        user.delete(:name)
        user = Utils.hash_replace_value(user, '-', nil)
        user = user.compact
        json_file.append(create_json_element(user))
        # return if i == 1
      }
      Utils.create_json_from_hash(json_file, @json_file_path)
      puts 'done'
    rescue => ex
      puts "#{ex.full_message}"
    end
  end

  #todo дописать запросы в базу echamps для получения id из базы для существующих позиций и переписат ьмодели других баз для исправления конфликтов
  def self.normalise_user(user)
    # require './models/echamps_model_new.rb'
    case @src_type
    when :zoon
      user.merge!(user_type: 'coach', position_id: 2)
      # user.merge!(country: 'Россия', region: 'Москва', city: 'Москва'}
      city = {country_id: 191, country_region_id: 2847, city_id: 3820210}
      user[:specialization] = Utils.normalize_string(user[:specialization])
      user[:education] = Utils.normalize_string(user[:education])
      user[:experience] = Utils.normalize_string(user[:experience])
      user[:info] = Utils.normalize_string(user[:info])
      user.merge!(city)

      specialization = user[:specialization].nil? ?
                           '' : "Специализация: <strong>#{user[:specialization]}</strong><br />"
      education = user[:education].nil? ?
                      '' : "Образование: <strong>#{user[:education]}</strong><br />"
      experience = user[:experience].nil? ?
                       '' : "Опыт: <strong>#{user[:experience]}</strong><br />"
      info = user[:info].nil? ?
                 '' : "Информация: <strong>#{user[:info]}</strong><br />"
      user[:about] = "<p>#{specialization}#{education}#{experience}#{info}</p>"
      user[:user_type] = 'coach'
      user[:source_link] = user[:source_url]

      user[:org] = Utils.symbolize_keys(Gym.where(id: user[:gym_id]).first.as_json)
      if user[:org]
        user[:org].map {|k, v| user[:org][k] = nil if user[:org][k] == '-'}
        # user[:org].merge!(country: 'Россия', region: 'Москва', city: 'Москва')
        user[:org][:address] = Utils.normalize_string(user[:org][:address])
        user[:org][:street] = user[:org].delete :address
        user[:org][:name] = user[:org].delete :title
        user[:org][:status] = true
        user[:org].merge!(city)
        user[:org].except!(:id, :rating, :comment, :created_at, :updated_at)
      end
      user.except!(:id, :rating, :info, :specialization, :education, :address,
                   :experience, :source_id, :gym_id,:created_at, :updated_at)
      puts 'zoom normalize'
    when :sportcubes
      user[:name] = "#{user[:name].split[-1]} #{user[:name].split[0]}"
      user.merge!(user_type: 'athlete', position_id: 1)
      user[:rank] = user.delete :achievement
      user[:rank] = Utils.convert_rank(user[:rank])
      if user[:coach].include?('Не указано')
        user[:about] = nil
      elsif user[:about] = "Тренеры:&nbsp;<strong>#{user[:coach].gsub(',', ', ')}</strong><br />"
      else
        user[:about] = "Тренер:&nbsp;<strong>#{user[:coach]}</strong><br />"
      end
      user[:year_of_birth] = user[:age].split('(')[-1].gsub(/[()]/, "").split[0]
      user[:city] = user[:city].gsub('г. ', '').strip
      user[:source_link] = user[:person_url]
      if user[:school] != 'Нет информации'
        user[:about].nil? ?
            user[:about] = "Спортшкола:&nbsp;<strong>#{user[:school]}</strong><br />" :
            user[:about] += "Спортшкола:&nbsp;<strong>#{user[:school]}</strong><br />"
      end

      user[:about] = "<p>#{user[:about]}</p>"
      # if user[:org][:city] == user[:city]
      #   city = EchampsBase.get_city_id(user[:org][:city])
      #   user.merge!(city)
      #   user[:org].merge!(city)
      # else
      #   puts "#{user[:org][:city]} not equals #{user[:city]}".red
      # end

      user[:events] = Utils.symbolize_keys(Competition.where(user_id: user[:id]).as_json)
      user[:events].collect {|event|
        event[:city_info] = Utils.remove_whitespaces(event[:city_info]) if !event[:city_info].nil?
        event.except!(:id, :user_id, :comp_id, :created_at, :updated_at)
        event.map {|k, v| event[k] = nil if event[k] == '-'}
        event[:discipline_kind] = "#{event[:discipline].split(',')[1].strip}  #{event[:discipline].split(',')[0]} м"
        event[:discipline_kind] += " (#{event[:length][0...-5].downcase})" if event[:length].include?('25')
        event[:discipline_kind] = event[:discipline_kind].gsub('комплекс', 'комплексное плавание')
        event[:sport_kind_id] = 63 #swimming
        event[:event_type_id] = 1 #competitions
        if !event[:city_info].nil? and event[:city_info].include?('(')
          event[:city_info] = "Место проведения: #{event[:city_info].split('(')[1].gsub(/[()]/, "").strip}<br>"
        else
          event[:city_info] = nil
        end
        event[:length] = "Длина бассейна: #{event[:length]}<br />" if !event[:length].nil?
        event[:fina_scores] = "Очки FINA: #{event[:fina_scores]}<br />" if !event[:fina_scores].nil?
        event[:info_src_url] = "Источник: <a href=\"#{event[:info_src_url]}\">#{event[:info_src_url]}</a><br />" if !event[:info_src_url].nil?
        event[:description] = "<p>#{event[:city_info]}\n#{event[:length]}\n#{event[:fina_scores]}\n#{event[:info_src_url]}</p>"

        event[:start_date] = event[:date].split[1].gsub('г.', '').gsub('-', '.')
        event[:end_date] = event[:date].split[3].gsub('г.', '').gsub('-', '.')
        # event[:result_place] = Utils.convert_latin_to_arabic(event[:result_place].split[0])
        event[:source_url] = event.delete :comp_url
        event[:name] = event.delete :title
        event[:rank] = event.delete :result_place

        event.except!(:discipline, :date, :length, :city_info, :fina_scores, :info_src_url)

        # event[:discipline_kind_id] = Event.get_discipline_kind_id(event[:sport_kind_id],
        #                                                           event[:discipline_kind])
        #
        # city = EchampsBase.get_city_id(event[:city])
        # event.merge!(city)
      }
      user.except!(:school, :person_url, :coach, :age, :id, :person_id, :created_at, :updated_at)
    when :nastart
      user[:name] = "#{user[:name].split[-1]} #{user[:name].split[0]}"
      user.merge!(user_type: 'athlete', position_id: 1)
      (user[:year_of_birth] = user[:birthday]; user[:birthday] = nil) if user[:birthday].length < 5

      if user[:city_team].include?('(')
        user.merge!({about: "Тренер: <strong>#{user[:city_team]
                                                   .split('(')[-1]
                                                   .gsub(/[()]/, "")}</strong><br />"})
        user[:city_team] = user[:city_team].split('(')[0].strip
      end

      user[:city_team] = sanitize_nastart_city_team(user[:city_team])

      case user[:city_team].split.count
      when 1
        if user[:city_team].include?('СШ')
          user[:school] = user[:city_team].split[0]
        else
          user[:city] = user[:city_team].split[0]
        end
        # puts "#{user[:city_team].split.count} #{user[:city_team]}".blue
      when 2
        user[:city] = user[:city_team].split[0]
        user[:school] = user[:city_team].split.drop(1).join(' ')
        # puts "#{user[:city_team].split.count} #{user[:city_team]}".blue
      when 3
        user[:city] = user[:city_team].split[0]
        user[:school] = user[:city_team].split.drop(1).join(' ')
        # puts "#{user[:city_team].split.count} #{user[:city_team]}".blue
      when 4
        user[:city] = user[:city_team].split.pop(2).join(' ')
        user[:school] = user[:city_team].split.drop(2).join(' ')
        # puts "#{user[:city_team].split.count} #{user[:city_team]}".cyan
      when 5
        user[:city] = user[:city_team].split.pop(2).join(' ')
        user[:school] = user[:city_team].split.drop(3).join(' ')
        # puts "#{user[:city_team].split.count} #{user[:city_team]}".cyan
      when 6
        user[:city] = user[:city_team].split.drop(2).pop(4).join(' ')
        user[:school] = user[:city_team].split.drop(2).join(' ')
        # puts "#{user[:city_team].split.count} #{user[:city_team]}".magenta
      when 7
        user[:city] = user[:city_team].split.pop(5).join(' ')
        user[:school] = user[:city_team].split.drop(2).join(' ')
        # puts "#{user[:city_team].split.count} #{user[:city_team]}".magenta
      else
        user[:school] = user[:city_team]
        puts "#{user[:city_team].split.count} #{user[:city_team]}".red
      end

      user.compact!
      if !user[:school].nil? and !user[:school].empty?
        user[:about].nil? ?
            user[:about] = "Спортшкола:&nbsp;<strong>#{user[:school]}</strong><br />" :
            user[:about] += "Спортшкола:&nbsp;<strong>#{user[:school]}</strong><br />"
      end
      user[:about] = "<p>#{user[:about]}</p>"

      # puts "#{user[:city_team]}"
      user[:events] = Utils.symbolize_keys(Competition.where(user_id: user[:id]).as_json)
      user[:events].collect {|event|
        event[:discipline] = Utils.remove_whitespaces(event[:discipline])
        if event[:discipline].include?('(') and event[:discipline].include?(')')
          event[:full_discipline] = event[:discipline]
          birth_members = event[:discipline].split(')')[-1].strip if event[:discipline].split(')').count > 1
          if event[:discipline].include?('препятстви')
            discipline = "#{event[:discipline].split[0]} #{event[:discipline].split[3]} #{event[:discipline].split[4]} #{event[:discipline].split[1]} #{event[:discipline].split[2]} #{event[:discipline].split[5]}".split('(')[0].strip.downcase
          else
            discipline = event[:discipline].split('(')[0].strip[0...-5].downcase
          end
          gender = event[:discipline].split('(')[-1].split(')')[0].strip
          event[:birth_members] = birth_members
          event[:gender] = gender == 'М' ? 'male' : 'female'
          event[:discipline] = discipline
        end
        event[:title] = event[:title][0...-1] if event[:title].strip[-1] == ','
        case event[:title].count(',')
        when 1
          event.merge!({name: event[:title].split(',')[0].strip,
                        city: event[:title].split(',')[1].gsub('г. ', '').strip})
        when 2
          event.merge!({name: event[:title].split(',')[0].strip,
                        facility_type: event[:title].split(',')[1].split(':')[0].strip,
                        facility: event[:title].split(',')[1].split(':')[-1].strip,
                        city: event[:title].split(',')[2].gsub('г. ', '').strip})
        when 3
          event.merge!({name: "#{event[:title].split(',')[0].strip}, #{event[:title].split(',')[1].strip}",
                        facility_type: event[:title].split(',')[2].split(':')[0].strip,
                        facility: event[:title].split(',')[2].split(':')[-1].strip,
                        city: event[:title].split(',')[3].gsub('г. ', '').strip})
        when 4
          begin
            event.merge!({name: event[:title].split(',')[0].strip,
                          members: "#{event[:title].split(',')[1].strip}, #{event[:title].split(',')[2].strip}",
                          facility_type: event[:title].split(',')[3].split(':')[0].strip,
                          facility: event[:title].split(',')[3].split(':')[-1].strip,
                          city: event[:title].split(',')[4].gsub('г.', '').strip})
          rescue
            puts 'error'
          end
        when 5
          event.merge!({name: "#{event[:title].split(',')[0].strip}, #{event[:title].split(',')[1].strip}",
                        members: "#{event[:title].split(',')[2].strip}, #{event[:title].split(',')[3].strip}",
                        facility_type: event[:title].split(',')[4].split(':')[0].strip,
                        facility: event[:title].split(',')[4].split(':')[-1].strip,
                        city: event[:title].split(',')[5].gsub('г. ', '').strip})
        when 6
          event.merge!({name: "#{event[:title].split(',')[0].strip}, #{event[:title].split(',')[1].strip}",
                        members: "#{event[:title].split(',')[2].strip}, #{event[:title].split(',')[3].strip}, #{event[:title].split(',')[4].strip}",
                        facility_type: event[:title].split(',')[5].split(':')[0].strip,
                        facility: event[:title].split(',')[5].split(':')[-1].strip,
                        city: event[:title].split(',')[6].gsub('г. ', '').strip})
        else
          puts "#{event[:title].count(',')} #{event[:title]}".red
        end
        event[:place] = event.delete :result_place

        event.except!(:id, :user_id, :comp_id, :title, :created_at, :updated_at)
      }
      user.except!(:id, :source_user_id, :city_team, :school, :created_at, :updated_at)
    end
  end

  def self.sanitize_nastart_city_team(str)
    return str.gsub('№ ', '№').gsub('г. ', '')
               .gsub('г.', '').gsub('м.р.', '')
               .gsub(",", ' ').delete(',')
               .gsub(/[\,]/, "")
               .gsub(/\s+/, ' ').strip
  end

  def self.create_json_element(user)
    user[:image_original_name] = user.delete :photo
    user[:internal_notes] = user.delete :phone

    user.merge!({user_id: nil, username: nil, username_canonical: nil,
                 email: nil, email_canonical: nil, roles: 'a:0:{}',
                 is_cms_user: false, enabled: true, password: nil,
                 status: true, user_agreement: true, gdpr_argreement: true,
                 is_created_user: true, user_profile_id: nil, gender: nil,
                 phone: nil, image_name: nil, user_org_id: nil, is_current: true,
                 user_profile_role_id: nil, sport_kind_id: nil, is_main: true
                })

    user[:user_roles] = []
    if !user[:specialty].nil? and user[:specialty].include?(',')
      user[:specialty].split(', ').each {|role|
        user[:user_roles].append(role: role)}
    elsif !user[:specialty].nil?
      user[:user_roles].append(role: user[:specialty])
    else
      user.delete(:user_roles)
    end
    return user.compact
  end

  def self.split_fio_str(fio_str)
    user_name = Hash.new
    names = fio_str.split
    user_name[:middle_name] = nil
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

  def self.load_users()
    begin
      case @src_type
      when :zoon
        require './models/zoon_model_2.rb'
        # get users as json
        @users = Coach.all.limit(10).as_json
        # @users = Coach.all.as_json
        @json_file_path = 'I:/dev_temp/zoon/echamps_zoon_upload_demo.json'
      when :sportcubes
        require './models/sportcubes_model.rb'
        # get users as json
        @users = User.all.limit(10).as_json
        # @users = User.all.as_json
        @json_file_path = 'I:/dev_temp/sportcubes/echamps_sportcubes_upload_demo.json'
      when :nastart
        require './models/nastart_model.rb'
        # get users as json
        @users = User.all.limit(10).as_json
        # @users = User.all.as_json
        @json_file_path = 'I:/dev_temp/nastart/echamps_nastart_upload_demo.json'
      end
    rescue => ex
      puts ex.message
    end
  end


  @src_type = :zoon
  load_users()
  iterate_users()
  puts 'end '
end