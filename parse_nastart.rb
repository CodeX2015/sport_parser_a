# encoding: utf-8
#
require 'nokogiri'
require 'open-uri'
require 'colorize'

require_relative 'utils/utils.rb'

def sanitize_strip_html(html_string)
  #encode_text = text_file.force_encoding('Windows-1251')
  # result = Nokogiri::HTML(html_string, nil, Encoding::UTF_8.to_s)

  result = Nokogiri::HTML.parse(html_string)
  return result.text
end

def decode_from_utf8_to_cp1251(string)
  return string.force_encoding("cp1251").encode("utf-8", undef: :replace)
end

def get_page_from_site(url)
  if url =~ /\A#{URI::regexp(['http', 'https'])}\z/
    # получаем список участников из файла
    page = open(url.to_s)
    doc = Nokogiri::HTML(page)
    return doc
  else
    puts("[WARN] wrong url #{url}")
  end
end

def save_to_file(file_path, doc)
  if File.exist?(file_path)
    puts("[WARN] #{file_path} already exist")
    return
  end
  begin
    File.write(file_path, doc)
  rescue :ex
    puts "[ERR] #{ex.message}"
  end
end

def download_photo(url, path)
  if url =~ /\A#{URI::regexp(['http', 'https'])}\z/
    if !File.exist?(path)
      loop do
        begin
          # puts "[INFO] download #{url} to #{path}"
          IO.copy_stream(open(url), path)
          break
        rescue => ex
          puts "[ERR] #{ex.message} #{url} #{path}"
          break
        end
      end
    else
      puts("[WARN] #{path} already exist")
    end
  else
    puts("[WARN] wrong url #{url}")
  end
end

def list_sportsmen
  param = '?page=person'
  pages = Nokogiri::HTML(open("#{@site}#{param}")).css('div.div_hidden').css('a')
  last_page = (pages[-1].text).scan(/\d/).join('').to_i
  count = pages.size

  # "http://www.nastart.org/index.php?page=person&page_num=2"

  (1..last_page).step(1) do |n|
    url = "#{@site}index.php?page=person&page_num=#{n}"
    persons_doc = get_page_from_site(url)
    continue if persons_doc.nil?
    persons_doc.css("table[cellpadding='5']").css('h1').css('a').each do |person|
      puts person['href']
      person_detail = get_page_from_site(person['href'])
      person_detail_html = person_detail.css("table[cellpading='9']").css("td[valign='top']")
      name = (person['href']).split('/')[-1]
      path = "#{@path}/#{name}.html"
      #puts "#{n} - сохраняю #{url}"
      save_to_file(path, person_detail)
    end

  end
  # pages.each do |page|
  #   puts "#{page.text}: page['href']"
  #   download_unior_page_from_site(#{page['href']}")
  # end

  puts 'end of script'

end

def parse_person_info(file)

  # ("table[cellpadding='5']")[]=>data_table
  #     [0].css('tr')[2]
  #         ('td')[0].css('a[href]')=>photo_url
  #         ('td')[1].text=>info
  #         ('td')[2].text=>about
  #
  #     ("table[bgcolor='#C4B0B0']")=>data_table
  #         ("tr[style="color: #FFFFFF"']")=>table_header
  #             ('td b').text=>table_header_cell
  #         ("tr[bgcolor='#F0EDED']")[]=>table_row
  #             ('td').text=>table_cell
  #             ('td[href]')=>table_link


  doc = Nokogiri::HTML(open(file)).css("table[cellpadding='5']")
  puts "[INFO] table[cellpadding='5'] = #{doc.count}"
  # parse info
  info_data_html = doc[0].css('td')
  puts "[INFO] info_data_html_count = #{info_data_html.count}"
  name = "name;#{info_data_html[0].at('h1').children.first.text.strip.delete("\t\n\r")}"
  if info_data_html[1].at_css('a')
    photo_url = "#{@site}#{info_data_html[1].css('a')[0]['href']}"
    photo_name = "#{photo_url.split("/")[-1]}"
    download_photo(photo_url, "#{@photo_path}/#{photo_name}")
  else
    photo_name = '-'
  end
  photo = "photo;#{photo_name}"
  # info = sanitize_strip_html(info_data_html[2].inner_html.strip.delete("\t\n\r").gsub("<br> ", "\n"))
  # arr_info = info.split("\n")
  info = sanitize_strip_html(info_data_html[2].inner_html.strip.delete("\t\n\r").gsub("<br> ", ";").gsub(":", ";"))
  info = info.split(";").map(&:lstrip).join(";").gsub("http;", "http:")
  about = info_data_html[3].text.strip.delete("\t\n\r").split.join(" ")
  about = "#{about.split(":")[0]};#{about.split(":").map(&:lstrip).drop(1).join(":").gsub(";", '')}"
  about = "О себе;-" if (about == ";" || about == "О себе;")

  hash_str = "#{@person_id};#{name};#{photo};#{info};#{about};"
  begin
    memberHash = Hash[*hash_str.split(';')] if !hash_str.empty?
    @about_hash_csv.to_a.append(memberHash) if !memberHash.empty?
  rescue => ex
    puts "[DEBUG] #{hash_str}"
    puts "\t[ERR] #{ex.backtrace}"
  end
  tables_html = doc.css("table[bgcolor='#C4B0B0']")

  puts "[INFO] table[bgcolor='#C4B0B0'] count is #{tables_html.count}"

  tables_html.each do |table_html|
    table_header_html = table_html.css("tr[style='color: #FFFFFF'] td b")
    puts "[INFO] table_header_count = #{table_header_html.count}"

    case table_header_html.count
    when 4 then
      # parse results
      puts "[INFO] parsing results table"
      results_html = doc.css("table[bgcolor='#C4B0B0']")[0]
      results_header = results_html.css("tr[style='color: #FFFFFF']")
      head = (results_header.text.delete("\r").split("\n")).drop(1)
      results_html.css("tr[bgcolor='#F0EDED']").each do |result_html|
        result_body = result_html.css('td')
        result_date = result_type = result_res = result_city = '-'
        result_date = result_body[0].text.strip.gsub(";", ".") if !result_body[0].text.strip.empty?
        result_type = result_body[1].text.strip.gsub(";", ".") if !result_body[1].text.strip.empty?
        result_res = result_body[2].text.strip.gsub(";", ".") if !result_body[2].text.strip.empty?
        result_city = result_body[3].text.strip.gsub(";", ".") if !result_body[3].text.strip.empty?
        hash_str = "#{@person_id};#{head[0]};#{result_date};#{head[1]};#{result_type};#{head[2]};#{result_res};#{head[3]};#{result_city};"
        begin
          memberHash = Hash[*hash_str.split(';')] if !hash_str.empty?
          @res_hash_csv.to_a.append(memberHash) if !memberHash.empty?
        rescue => ex
          puts "[DEBUG] #{hash_str}"
          puts "\t[ERR] #{ex.message}"
        end
      end
    when 5 then
      # parse competition
      puts "[INFO] parsing competitions table"
      competition_html = doc.css("table[bgcolor='#C4B0B0']")
      puts "[INFO] comp_table_cnt = #{competition_html.count}"
      competition_html = competition_html[1] if competition_html.count > 1

      if competition_html
        competition_header = competition_html.css("tr[style='color: #FFFFFF']")
        competition_header_arr = (competition_header.text.delete("\r").split("\n")).drop(1)
        competition_html.css("tr[bgcolor='#F0EDED']").each do |competition_html|
          competition_body = competition_html.css('td')
          competition_date = competition_type = competition_res = competition_place = competition_comp = '-'
          competition_date = "#{competition_header_arr[0]};#{competition_body[0].text.strip}" if !competition_body[0].text.strip.empty?
          competition_type = "#{competition_header_arr[1]};#{competition_body[1].text.strip}" if !competition_body[1].text.strip.empty?
          competition_res = "#{competition_header_arr[2]};#{competition_body[2].text.strip}" if !competition_body[2].text.strip.empty?
          competition_place = "#{competition_header_arr[3]};#{competition_body[3].text.strip}" if !competition_body[3].text.strip.empty?
          competition_comp = "#{competition_header_arr[4]};#{sanitize_strip_html(
              competition_body[4].inner_html.strip.delete("\t\n\r").gsub("<br>", ", "))}" if !sanitize_strip_html(
              competition_body[4].inner_html.strip.delete("\t\n\r").gsub("<br>", ", ")).empty?

          if competition_body[4].at_css('a')
            competition_url = "competition_url;#{@site}" + competition_body[4].at('a')['href']
            competition_id = "competition_id;#{competition_url.split('=')[-1]}"
            # competition_url_text = competition_body[4].css('a').text
          end

          hash_str = "#{@person_id};#{competition_date};#{competition_type};#{competition_res};#{competition_place};#{competition_comp};#{competition_url};#{competition_id};"
          begin
            memberHash = Hash[*hash_str.split(';')] if !hash_str.empty?
            @comp_hash_csv.to_a.append(memberHash) if !memberHash.empty?
          rescue => ex
            puts "[DEBUG] #{hash_str}"
            puts "\t[ERR] #{ex.message}"
          end
        end
      else
        puts "[ERR] something wrong parsing tables"
      end
    else
      puts "[ERR] unknown statement of header_count(#{table_header_html.count})"
    end
  end
  puts "\n\t[INFO] end of parsing..."
end

def parse_sportsmen
  person_counter = 0
  files = Dir.glob("#{@path}**/*.html")
  files.each do |file|
    @person_id = "id;#{file.split("/")[-1].split(".")[0]}"
    person_counter += 1
    puts "\t[INFO] #{person_counter}/#{files.size}: обрабатываю #{file}"
    parse_person_info(file)
    # break
  end
end

def load_protocols_from_csv
  competitions_hash = Utils.read_csv_file("assets/nastart/parse_competition.csv")

  competitions_hash.each do |elem|
    url = "http://www.nastart.org/print.php?id_comp=#{elem['comp_id']}"
    doc = Nokogiri::HTML.parse(open(url))
    header = doc.css('center')
    body = doc.css("table[style='font-size: 10pt']")
    save_to_file("assets/nastart/protocols/#{elem['comp_id']}.html", "#{header}\n#{body}")
  end
end

def load_protocols_from_json
  competitions_hash = Utils.read_json_file("assets/nastart/absent_comps.json")
  i = 0
  competitions_hash.each do |elem|
    i += 1
    url = "http://www.nastart.org/print.php?id_comp=#{elem['comp_id']}"
    doc = Nokogiri::HTML.parse(open(url))
    header = doc.css('center')
    body = doc.css("table[style='font-size: 10pt']")
    save_to_file("assets/nastart/protocols/#{elem['comp_id']}.html", "#{header}\n#{body}")
    puts "#{i} from #{competitions_hash.count}" if i % 10 == 0
  end
end

def parse_protocol_info(file)
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

def parse_protocols

  protocol_counter = 0
  files = Dir.glob("#{@protocol_path}**/*.html")
  files.each do |file|
    @protocol_id = "id;#{file.split("/")[-1].split(".")[0]}"
    protocol_counter += 1
    puts "\t[INFO] #{protocol_counter}/#{files.size}: обрабатываю #{file}"
    parse_protocol_info(file)
  end
end

def nastart_write_to_db_protocols
  data = Utils.read_csv_file("#{@appDir}/protocol_competitions.csv")
  require './models/nastart_model.rb'
  i = 0
  data.each do |elem|
    i += 1
    puts "#{i} из #{data.count} #{elem['id']} #{elem['Ф.И.О.']} #{elem['Дисциплина']}" if i % 1000 == 0
    # puts "#{i} из #{data.count} #{elem['id']} #{elem['Ф.И.О.']} #{elem['Дисциплина']}" if i % 10 == 0
    begin
      raise('user ФИО is null. Skipping..') if elem['Ф.И.О.'].strip.empty?
      user = User.where('name LIKE ? AND birthday LIKE ?',
                        "%#{Utils.titleize_fio(elem['Ф.И.О.'])}%", "%#{elem['Год рождения']}%")
      if user.exists?
        # puts "#{user.first.name} существует"
        if !(user.first.competitions.find_by(comp_id: elem['id'], discipline: elem['Дисциплина']))
          user.first.competitions.create(
              comp_id: elem['id'],
              source_url: "http://nastart.org/index.php?page=commshow&type=comp&id_comp=#{elem['id']}",
              title: elem['Протокол'],
              discipline: elem['Дисциплина'],
              result: elem['Результат'],
              result_place: elem['Место']
          )
          # puts "#{user.first.name} CREATE #{elem['id']} \"#{elem['Дисциплина']}\" \"#{elem['Место']}\"".blue
        end
      else
        user = User.create(
            name: Utils.titleize_fio(elem['Ф.И.О.']),
            birthday: elem['Год рождения'],
            city_team: elem['город / команда (тренер)']
        )
        user.competitions.create(
            comp_id: elem['id'],
            source_url: "http://nastart.org/index.php?page=commshow&type=comp&id_comp=#{elem['id']}",
            title: elem['Протокол'],
            discipline: elem['Дисциплина'],
            result: elem['Результат'],
            result_place: elem['Место']
        )
      end
    rescue => ex
      puts "\n\t#{i} из #{data.count} #{elem['id']} \"#{elem['Ф.И.О.']}\" #{elem['Протокол']} #{elem['Дисциплина']}".red
      puts "\t[ERR] #{ex.message}\n".red
    end

  end
end

def update_db_data
  absent_hash = []
  users = Utils.read_json_file("#{@appDir}/parse_person.json")
  require './models/nastart_model.rb'
  # res = User.where(id: '116917')
  # puts Utils.titleize(Utils.remove_whitespaces(res.first.name))
  # res.update(name: Utils.titleize(Utils.remove_whitespaces(res.first.name)))
  # return
  i = 0
  users.map {|user|
    i += 1
    begin
#       if user['comp_results'].count > 1
#         res1 = user['comp_results'][0]
#         res1name = User.joins(:competitions).where(
#             'comp_id = ? AND result LIKE ? AND 
# result_place LIKE ? AND competitions.discipline LIKE ?',
#             res1['comp_id'],
#             res1['results'],
#             res1['place'],
#             "%#{res1['discipline']}%"
#         )
# 
#         res2 = user['comp_results'][1]
#         res2name = User.joins(:competitions).where(
#             'comp_id = ? AND result LIKE ? AND 
# result_place LIKE ? AND competitions.discipline LIKE ?',
#             res2['comp_id'],
#             res2['results'],
#             res2['place'],
#             "%#{res2['discipline']}%"
#         )
#         if res1name.first.name == res2name.first.name
#           puts "user: #{user['name']}: #{res1name.first.name} == #{res2name.first.name}".blue
#         else
#           puts "user: #{user['name']}: #{res1name.first.name} != #{res2name.first.name}".red
#         end
#         #todo update more than 1 results
#       elsif user['comp_results'].count > 0
#         res1 = user['comp_results'][0]
#         res1name = User.joins(:competitions).where(
#             'comp_id = ? AND result LIKE ? AND 
# result_place LIKE ? AND competitions.discipline LIKE ?',
#             res1['comp_id'],
#             res1['results'],
#             res1['place'],
#             "%#{res1['discipline']}%"
#         )
# 
#         if (user['name'] == res1name.first.name)
#           puts "user: #{user['name']} != #{res1name.first.name}".blue
#         else
#           puts "user: #{user['name']} != #{res1name.first.name}".red
#         end
#         puts "Is it true?"
#         answer = gets.chomp
#         puts "#{answer}"
#         #todo update if 1 results
#       else
#         puts "user #{user['name']} has no results".cyan
#         #todo update if no results
#       end
#       user['name'] = Utils.titleize(user['name'])
      user['comp_results'].map {|comp|
        absent_comp = ''
        memberHash = []
        if !comp['real_name']
          real_name = User.joins(:competitions).where(
              'comp_id = ? AND result LIKE ? AND result_place LIKE ? AND competitions.discipline LIKE ?',
              comp['comp_id'],
              "%#{comp['results']}%",
              "%#{comp['place']}%",
              "%#{comp['discipline']}%"
          )
          if real_name.exists?
            comp['real_name'] = real_name.first.name
          else
            # puts "SELECT * FROM users INNER JOIN competitions ON competitions.user_id = users.id
            # WHERE (comp_id = #{comp['comp_id']} AND result LIKE '%#{comp['results']}%'
            # AND result_place LIKE '%#{comp['place']}%'
            # AND competitions.discipline LIKE '%#{comp['discipline']}%')"
            # puts "comp_id: #{comp['comp_id']}, user: #{user['name']}".red
            absent_comp = "comp_id;#{comp['comp_id']};comp_url;#{comp['comp_url']};"
          end
        end
        memberHash = Hash[*absent_comp.split(";")] if !absent_comp.empty?

        if !memberHash.empty?
          # puts memberHash['comp_id']
          if !absent_hash.any? {|h| h['comp_id'] == memberHash['comp_id']}
            absent_hash.to_a.append(memberHash)
          end
        end
        if !comp['real_user_id'] and comp['real_name']
          real_user = User.where(name: comp['real_name'])
          comp['real_user_id'] = real_user.first.id if real_user.exists?
        end
        # puts real_name.first.name
      }
      puts "#{i} из #{users.count} user: #{user['name']}, res_count: #{user['comp_results'].count}" if i % 500 == 0
        # break 
    rescue => ex
      puts "\n\t#{i} из #{users.count} #{user['name']}".red
      puts "\t[ERR] #{ex.message}\n".red
    end
  }
  Utils.create_json_from_hash(users, "#{@appDir}/parse_person_fix.json")

  Utils.create_json_from_hash(absent_hash, "#{@appDir}/absent_comps.json")
end


def merge_data
  merged_data = []
  count_comp = 0
  person_file = "#{@appDir}/parse_about_person.csv"
  users = Utils.read_csv_file(person_file)
  comp_file = "#{@appDir}/parse_competition.csv"
  comps = Utils.read_csv_file(comp_file)
  users.each {|user|
    select = comps.select {|value| value['id'] == user['id']}
    select.each {|h| h.delete('id')}
    count_comp += select.count
    memberHash = user
    memberHash['comp_results'] = select
    merged_data.to_a.append(memberHash) if !memberHash.empty?
    # p user['id']
    # break
  }
  puts users.count, comps.count, merged_data.count, count_comp
  json = Utils.convert_hash_to_json(merged_data)
  # puts json
  save_to_file("#{@appDir}/parse_person.json", json)
end

def update_db_nastart

  require './models/nastart_model.rb'
  comps = Competition.all
  comps.each {|comp|
    begin
      # puts comp.comp_id
      # comp.update(result: Utils.remove_whitespaces(comp.result))

      # comp.add_column(comp_url: :text)
      comp.update(source_url: "http://nastart.org/index.php?page=commshow&type=comp&id_comp=#{comp.comp_id}")
    rescue => ex
      puts "\n\tid - #{comp.comp_id} }"
      puts "\n\t[ERR] #{ex.message}"
    end
  }
end

def update_db_nastart2

  require './models/nastart_model.rb'
  users = User.all
  users.each {|user|
    begin
      puts user.competitions.each {|comp| puts comp.comp_id}
    rescue => ex
      puts "\n\tid - #{user.comp_id} }"
      puts "\n\t[ERR] #{ex.message}"
    end
  }
end

def fix_data2
  data = Utils.read_json_file('I:/dev_temp/nastart/parse_person.json')
  # data.map {|elem| elem['name'] = Utils.sanitize_char_except_letters(elem['name'])}
  data.map {|elem|
    if elem['comp_results']
      elem['comp_results'].map {|res|
        # res['results'] = res['results'].split('(').join(' (')
        res['results'] = Utils.remove_whitespaces(res['results'])
      }
    end
  }
  Utils.create_json_from_hash(data, 'I:/dev_temp/nastart/parse_person_fix.json')
end

def update_nastart
  data = Utils.read_json_file('I:/dev_temp/nastart/parse_person.json')
  data.each {|elem|
    results = elem['comp_results']
    if results.count > 0
      results.each {|res|
        puts "#{res['comp_id']}, #{res['discipline']}, #{res['results']}, #{res['place']}"

        puts "SELECT users.name FROM competitions INNER JOIN users ON competitions.user_id=users.id WHERE (comp_id = \'#{res['comp_id']}\' AND discipline LIKE \'%#{res['discipline']}%\' AND result LIKE \'%#{res['results']}%\' AND result_place LIKE \'%#{res['place']}%\')"
        # prev_name = comp_db.users.name
        #
      }
    end
  }
end

def main
  if DEBUG
    @appDir = "I:/dev_temp/nastart"
  else
    @appDir = 'assets/nastart'
  end
  @photo_path = "#{@appDir}/photo"
  @path = "#{@appDir}/unior_page"
  @path = "#{@appDir}/download"
  @protocol_path = "#{@appDir}/protocols"
  # @protocol_path = "#{@appDir}/test_protocols"
  @site = 'http://www.nastart.org/'


  # update_db_nastart
  # fix_data2
  # update_db_data
  # merge_data
  # return

  # puts Utils.titleize("СТЕПАНОВА ЕКАТЕРИНА").red
  # return

  nastart_write_to_db_protocols
  return

  # 9139 из 369938 ТРИФОНОВА КРИСТИНА Бег 1000  метров (Ж) 1998-2000
  # 9140 из 369938 Гурьева Анжела Бег 1000  метров (Ж) 1998-2000
  # 9141 из 369938 Васильева Настя Бег 1000  метров (Ж) 1998-2000
  # 9142 из 369938 СТЕПАНОВА ЕКАТЕРИНА Бег 1000  метров (Ж) 1998-2000
  # 9143 из 369938 Яковлева Алла Бег 1000  метров (Ж) 1998-2000
  # 9144 из 369938 ЕФИМОВА ЮЛИЯ Бег 1000  метров (Ж) 1998-2000
  # 9145 из 369938 ГРИГОРЬЕВА МАРИЯ Бег 1000  метров (Ж) 1998-2000
  # 9146 из 369938  Бег 1000  метров (Ж) 1998-2000
  # http://nastart.org/print.php?id_comp=208
  # http://nastart.org/index.php?page=protocol&id_comp=825
  # http://nastart.org/index.php?page=commshow&type=comp&id_comp=1847
  # http://nastart.org/person/010112390210012/


  # Parse sportsmens
  # @res_hash_csv = []
  # @comp_hash_csv = []
  # @about_hash_csv = []
  # list_sportsmens
  # parse_sportsmans
  # create_csv_from_hash(@about_hash_csv, "#{@appDir}/parse_about_person.csv") if !@about_hash_csv.empty?
  # create_csv_from_hash(@res_hash_csv, "#{@appDir}/parse_results.csv") if !@res_hash_csv.empty?
  # create_csv_from_hash(@comp_hash_csv, "#{@appDir}/parse_competition.csv") if !@comp_hash_csv.empty?

  # Load protocols
  # load_protocols_from_csv
  # load_protocols_from_json

  # Parse protocols
  # @protocol_hash = []
  # parse_protocols
  # Utils.create_csv_from_hash(@protocol_hash, "#{@appDir}/protocol_competition.csv") if !@protocol_hash.empty?

  # Utils.convert_json_to_csv("#{@appDir}/protocol_competition.json")
end

DEBUG = true
main