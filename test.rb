require_relative 'utils/utils.rb'
require 'colorize'

Encoding::default_external = Encoding::UTF_8
# Encoding::default_external = 'cp1251'

@appDir = "I:/dev_temp/nastart"

def first_method
  file = "assets/nastart/protocols/806.csv"
  filename = "#{File.dirname(file)}/#{File.basename(file, '.csv')}.json"
  puts filename
  return

  str = "3881(7,79 622 | 6,4 675 | 9,97 484 | 8,96 755 | 1,79 619 | 2.53,81 726)"
  res1 = str.split('(').join(' (')
  res2 = res1
  puts res2
  return
# coding: IBM866 Encoding.default_external = Encoding::IBM866 Encoding.default_internal = Encoding::IBM866
  Encoding::default_external = Encoding::UTF_8

  puts 'Башкирцев Денис' == 'Ткачева Екатерина'

  p Encoding::default_external
  p 'тестирование'
  puts 'тестирование'.red
  puts 'тестирование'.blue
  puts 'тестирование'.cyan
  puts 'тестирование'.magenta

  return
# require './models/test_model.rb'
#   Competition.check_columns


  return

  comps = Competition.where(comp_id: '496')
  test = Utils.convert_db_object_to_json(comps)
  array_of_hashes = comps.as_json
  aar_of_os = array_of_hashes.map {|arr| OpenStruct.new(arr)}
  puts aar_of_os[0].id
  puts 'end'
end

def filling_db_from_json(json_file)
  require './models/nastart2_model.rb'
  data = Utils.read_json_file(json_file)
  i = 0
  data.each do |user|
    puts user['name']
    user_db = User.create(
        name: user['name'],
        photo: user['photo'],
        birthday: user['birthday'],
        city_team: user['city_team'],
        nickname: user['nickname'],
        growth: user['growth'],
        weight: user['weight'],
        discipline: user['discipline'],
        achievement: user['achievement'],
        about: user['about'],
        source_user_id: user['source_user_id'],
        source_user_url: user['source_user_url']
    )
    user['comp_results'].each {|comp|
      puts comp['title']
      discipline_db = Discipline.where(title: comp['discipline'])
      if discipline_db.exists?
        discipline_db = discipline_db.first
      else
        discipline_db = Discipline.create(
            title: comp['discipline']
        )
      end

      comp_db = Competition.where(source_comp_id: comp['comp_id'])
      if comp_db.exists?
        comp_db = comp_db.first
      else
        comp_db = Competition.create(
            title: comp['title'],
            city: comp['city'],
            source_comp_id: comp['comp_id'],
            source_comp_url: "http://nastart.org/index.php?page=commshow&type=comp&id_comp=#{comp['comp_id']}"
        )
      end

      result_db = user_db.results.where(date: comp['date'],
                                        time: comp['results'],
                                        place: comp['place'],)
      if result_db.exists?
        result_db = result_db.first
      else
        result_db = user_db.results.create(
            date: comp['date'],
            time: comp['results'],
            place: comp['place'],
            user_id: user_db.id,
            competition_id: comp_db.id,
            discipline_id: discipline_db.id
        )
      end

      puts 'comp 1'
    }
  end
  puts 'user 1'
end

def filling_db_from_json_2(json_file)
  require './models/nastart2_model.rb'
  data = Utils.read_json_file(json_file)
  i = 0
  data.each do |comp|
    # puts comp['title']

    comp_db = Competition.where("source_comp_id = ? OR title LIKE ?",
                                comp['comp_id'],
                                "%#{comp['title']}%")
    if comp_db.exists?
      comp_db = comp_db.first
      # comp_db.update(
      #     title: comp['title'],
      #     # city: comp['city'],
      #     source_comp_id: comp['comp_id'],
      #     source_comp_url: "http://nastart.org/index.php?page=commshow&type=comp&id_comp=#{comp['comp_id']}"
      # )
    else
      comp_db = Competition.create(
          title: comp['title'],
          # city: comp['city'],
          source_comp_id: comp['comp_id'],
          source_comp_url: "http://nastart.org/index.php?page=commshow&type=comp&id_comp=#{comp['comp_id']}"
      )
    end

    next if comp['results'].nil?
    comp['results'].each {|user|
      # puts user['Ф.И.О.']
      discipline_db = Discipline.where(title: user['Дисциплина'])
      if discipline_db.exists?
        discipline_db = discipline_db.first
      else
        discipline_db = Discipline.create(
            title: user['Дисциплина']
        )
      end

      user_db = User.where('name LIKE ? AND city_team LIKE ?',
                           "%#{user['Ф.И.О.']}%",
                           "%#{user['город / команда (тренер)']}%")
      if user_db.exists?
        user_db = user_db.first
        # user_db.update(
        #     name: user['Ф.И.О.'],
        #     birthday: user['Год рождения'],
        #     city_team: user['город / команда (тренер)']
        # )
      else
        user_db = User.create(
            name: user['Ф.И.О.'],
            birthday: user['Год рождения'],
            city_team: user['город / команда (тренер)']
        )
      end
  
      result_db = Result.where(time: user['Результат'],
                               place: user['Место'])
      if result_db.exists?
        result_db = result_db.first
        result_db.update(
            time: user['Результат'],
            place: user['Место'],
            user_id: user_db.id,
            competition_id: comp_db.id,
            discipline_id: discipline_db.id
        )
      else
        result_db = Result.create(
            # date: user['date'],
            time: user['Результат'],
            place: user['Место'],
            user_id: user_db.id,
            competition_id: comp_db.id,
            discipline_id: discipline_db.id
        )
      end
    }
  end
end

def check_db
  require './models/nastart2_model.rb'
  users = User.all
  puts '1'
end

def parse_protocols(protocol_path)
  @protocol_hash = []
  i = 0
  files = Dir.glob("#{protocol_path}**/*.html")
  files.each do |file|
    @protocol_id = "id;#{file.split("/")[-1].split(".")[0]}"
    i += 1
    puts "\t[INFO] #{i}/#{files.size}: обрабатываю #{file}" if i % 100 == 0
    parse_protocol_info(file)
    # break if i == 5
  end
  Utils.create_csv_from_hash_with_headers(@protocol_hash, "#{@appDir}/protocol_competitions.csv") if !@protocol_hash.empty?
end

def parse_protocol_info(file)
  require 'nokogiri'
  doc = Nokogiri::HTML(open(file), nil, 'Windows-1251')
  protocol_header = "Протокол;#{doc.css('center b').text.delete("\n\r\t").strip}"
  doc_body = doc.css('table')
  table_row = doc_body.css('tr')
  row_count = 0
  comp_type = ''
  table_header_arr = []
  table_row.each do |row|
    row_count += 1
    if row['bgcolor'] == '#FFFFFF'
      comp_type = "Дисциплина;#{row.text.delete("\n\r\t").strip}"
      # puts "comp_type #{elem.text.delete("\n\r\t")}"
    elsif row['bgcolor'] == '#CCCCCC'
      table_row_text = row.text.delete("\r\t").strip
      table_header_arr = table_row_text.split("\n")
      # puts "comp_table_headers #{table_header_arr.join(";")}"
    else
      row_text = row.text.delete("\r\t").strip
      # if row_text.include?("Шведов Роман")
      #   # puts 1
      # end
      table_row_arr = row_text.split("\n")
      # .reverse.drop(2).reverse
      # puts "comp_table_row #{table_row_arr.join(";")}"
      begin
        combine_arr = table_header_arr.zip(table_row_arr)
        combine_arr = combine_arr.map {|elem1| elem1.map {|elem2| elem2 ? elem2 : "-"}}
        hash_str = "#{@protocol_id};#{protocol_header};#{comp_type};#{combine_arr.join(";")}"
        hash_str = Utils.remove_whitespaces(hash_str)
        memberHash = Hash[*hash_str.split(";")] if !hash_str.empty?
        @protocol_hash.to_a.append(memberHash) if !memberHash.empty?
      rescue => ex
        puts "[DEBUG] #{hash_str}"
        puts "\t[ERR] #{ex.message}"
      end
    end
    # puts row_count
  end
  # puts "end".to_s.force_encoding('Windows-1251').encode('utf-8')
end


# protocol_path = "#{@appDir}/protocols"
# parse_protocols(protocol_path)


# check_db
# filling_db_from_json('I:/dev_temp/nastart/test_data.json')
filling_db_from_json_2('I:/dev_temp/nastart/protocol_competitions_1.json')

def convert_protocols_2
  data = Utils.read_csv_file("#{@appDir}/protocol_competitions_demo.csv")
  i = 0
  # res = data.group_by{|h| [h['id'], h['Протокол']]}
  # res = data.group_by {|h| [h.delete('id'), h.delete('Протокол')]}
  # .map {|k, v| {id: k[0], protocol: k[1], results:
  #     v.group_by {|h| h.delete('Дисциплина')}.map {|k, v| {discipline: k, data: v}}
  # }}
  json = data.group_by {|h| [h.delete('id'), h.delete('Протокол')]}
             .map {|k, v| {comp_id: k[0], title: k[1], results: v}}
  # res = data.group_by{|h| h.delete('id')}.map{|k, v| {id: k, data: v}}

  Utils.create_json_from_hash(json, "#{@appDir}/protocol_competitions_demo.json")
end

def convert_protocols
  json = []
  data = Utils.read_csv_file("#{@appDir}/protocol_competitions_demo.csv")
  comp = Hash.new
  result = Hash.new
  user = Hash.new
  i = 0
  data.each {|row|
    i += 1

    if !(comp['id'] == row['id'])
      if !comp.empty?
        puts "Add to json #{comp['id']} results_count: #{comp['results'].count}"
        json.append(comp)
        comp = Hash.new
      end

      comp['id'] = row['id']
      comp['title'] = row['Протокол']

      user['name'] = row['Ф.И.О.']
      user['birthday'] = row['Год рождения']
      user['city_team'] = row['город / команда (тренер)']
      user['place'] = row['Место']
      user['time'] = row['Результат']

      result['discipline'] = row['Дисциплина']
      result['users'] = [] if result['users'].nil?
      result['users'].append(user)
      user = Hash.new
    else
      if result['discipline'] == row['Дисциплина']
        user['name'] = row['Ф.И.О.']
        user['birthday'] = row['Год рождения']
        user['city_team'] = row['город / команда (тренер)']
        user['place'] = row['Место']
        user['time'] = row['Результат']
        result['discipline'] = row['Дисциплина']

        result['users'] = [] if result['users'].nil?
        result['users'].append(user)
        user = Hash.new
        puts "Create User: #{user['name']}"
      else
        comp['results'] = [] if comp['results'].nil?
        comp['results'].append(result)
        result = Hash.new

        user['name'] = row['Ф.И.О.']
        user['birthday'] = row['Год рождения']
        user['city_team'] = row['город / команда (тренер)']

        result['discipline'] = row['Дисциплина']


        # result['users'] = [] if result['users'].nil?
        # result['users'] << (user)
        # puts "Create Result: #{result['discipline']}, user_count: #{result['users'].count}"
      end
    end
    if i == data.count
      result['users'] = [] if result['users'].nil?
      result['users'].append(user)
      user = Hash.new
      comp['results'] = [] if comp['results'].nil?
      comp['results'].append(result)
      result = Hash.new
      puts "Add last Comp: #{comp['id']} results_count: #{comp['results'].count}"
      json.append(comp)
      comp = Hash.new
    end

    # puts '1'
  }
  Utils.create_json_from_hash(json, "#{@appDir}/protocol_competitions_demo.json") if !json.empty?
end

# convert_protocols_2

class User
  def initialize(name, birthday, city_team, place, time, discipline)
    @name = name
    @birthday = birthday
    @city_team = city_team
    @place = place
    @time = time
    @discipline = discipline
  end
end

# descipline_db = Discipline.create(
#     title: comp['descipline']
# )
# comp_db = Competition.create(
#     title: comp['title'],
#     city: comp['city'],
#     source_comp_id: comp['comp_id'],
#     source_comp_url: "http://nastart.org/index.php?page=commshow&type=comp&id_comp=#{comp['comp_id']}"
# )
# result_db = user_db.results.create(
#     date: comp['date'],
#     time: comp['results'],
#     place: comp['place'],
#     user_id: user_db.id,
#     competition_id: comp_db.id,
#     descipline_id: descipline_db.id
# )
#
# discipline_db = user_db.disciplines.create(
#           title: comp['discipline']
#       )
#       comp_db = user_db.competitions.create(
#           title: comp['title'],
#           city: comp['city'],
#           source_comp_id: comp['comp_id'],
#           source_comp_url: "http://nastart.org/index.php?page=commshow&type=comp&id_comp=#{comp['comp_id']}"
#       )
#       result_db = user_db.results.create(
#           date: comp['date'],
#           time: comp['results'],
#           place: comp['place'],
#           user_id: user_db.id,
#           competition_id: comp_db.id,
#           discipline_id: discipline_db.id
#       )

