require 'nokogiri'
require 'open-uri'
require_relative 'utils/utils.rb'


def get_html_results(comp_id, discipline_id)
  require 'rest-client'

  url = "#{@site}callback.comp.php?c=#{comp_id}&d=#{discipline_id}"
  headers = {"Referer": "#{@site}?page=competitions&c=#{comp_id}", "X-Requested-With": "XMLHttpRequest"}
  response = RestClient.get(url, headers)
  return response
end

def decode_from_cp1251_to_utf8(string)
  return string.to_s.force_encoding("cp1251").encode("utf-8", {invalid: :replace, undef: :replace, replace: ''})
  # require 'iconv'
  # return Iconv.conv("UTF-8", "Windows-1251", string)
end

def sanitize_strip_html(html_string)
  #encode_text = text_file.force_encoding('Windows-1251')
  # result = Nokogiri::HTML(html_string, nil, Encoding::UTF_8.to_s)
  result = Nokogiri::HTML.parse(html_string)
  return result
end

# result = sanitize_strip_html(decode_from_cp1251_to_utf8(get_html_results))
# puts result.inner_html

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

def download_file(url, path)
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

def save_to_file(file_path, raw_text)
  # puts("[INFO] save file #{file_path}")
  if File.exist?(file_path)
    puts("[WARN] #{file_path} already exist")
    return
  end
  begin
    File.write(file_path, raw_text)
  rescue => ex
    puts "\t[ERR] #{ex.message}\n\n"
    puts "\t[ERR] #{ex.backtrace}"
  end
end

def list_years

  # ("div.panel-body")
  #     .css('p a')[]
  #     .css("a['href']")=>years
  param = '?page=competitions'
  year_pages = Nokogiri::HTML(open("#{@site}#{param}")).css('div.panel-body').css('p a')

  # last_page = (years_pages[-1].text).scan(/\d/).join('').to_i
  year_count = year_pages.size

  # puts "[INFO] #{year_count} year pages"
  # puts year_pages
  # "https://sportcubes.ru/?page=competitions&y=2016"

  # list year pages
  (0..year_count - 1).step(1) do |n|
    # puts "[INFO] year_URL=#{url}"
    url = "#{@site}#{param}&y=#{year_pages[n].text}"
    @year = year_pages[n].text
    year_doc = get_page_from_site(url)
    month_pages = year_doc.css('div.panel-body').css("a[role='button']")
    month_count = month_pages.size
    # puts "[INFO] #{year_pages[n].text} #{month_count} month pages"

    # list month pages
    (0..month_count - 1).step(1) do |m|
      # puts "[INFO] month_URL=#{month_pages[m]['href']} "
      url = "#{month_pages[m]['href']}"
      @month = month_pages[m]['href'].split('=')[-1]
      month_doc = get_page_from_site(url)
      puts "[INFO] #{year_pages[n].text} month_URL=#{month_pages[m]['href']} "
      parse_competitions(month_doc)
      # only one month
      # break
    end
    # only one year
    # break
  end
end

def parse_competitions(html_doc)
  comp_doc = html_doc.css('div.container-fluid')
  comp_list = comp_doc.css('div.container-fluid').css("table.table-striped").css('tr')
  # puts "[INFO] #{comp_list.size} competitions page"
  continue if comp_list.nil?
  comp_list.each do |comp_row|
    comp_row_html = comp_row.css('td')[0].css('a')[0]
    if comp_row_html
      if comp_row_html.text.include?("/")
        comp_date_range = comp_row_html.text.delete("\t\n\r").split('/')[0].strip
        comp_name = comp_row_html.text.delete("\t\n\r").split('/')[-1].strip
      else
        comp_name = comp_row_html.text.delete("\t\n\r")
        comp_date_range = '-'
      end
      comp_url = "#{@site}#{comp_row_html['href']}"
      comp_id = comp_url.split('=')[-1]
      hash_str = "comp_id;#{comp_id};year;#{@year};month;#{@month};date_range;#{comp_date_range};comp_name;#{comp_name};comp_url;#{comp_url};"
      # puts "#{hash_str}"
      begin
        memberHash = Hash[*hash_str.split(';')] if !hash_str.empty?
        @comp_hash_csv.to_a.append(memberHash) if !memberHash.empty?
      rescue => ex
        puts "[ERR] #{ex.backtrace}"
      end

      # get comp details page
      comp_detail = get_page_from_site(comp_url)
      comp_detail_html = comp_detail.css('div.container-fluid')
      path = "#{@path}/#{comp_id}.html"
      # puts "[INFO] #{comp_name} - сохраняю #{comp_id}"
      # save_to_file(path, comp_detail_html)
      # only one competition
      # break
    else
      puts "[ERR] something wrong parsing"
      puts "[DEBUG] comp_row = #{comp_row.css('td')[0]}"
    end
  end
end

def get_competitions
  # ("div.panel-body")
  #     .css('p a')[]
  #     .css("a['href']")=>years
  #                            .css('a')
  #                            .css("a['href']")=>months
  # ("div.container-fluid")
  #     .css("table[class='table table-striped'] tr")[]
  #     .css('td a')[0]['href']=>comp_url


  @comp_hash_csv = []
  @year = @month = ''
  list_years
  Utils.create_csv_from_hash_with_headers(@comp_hash_csv, "#{@appDir}/parse_competition.csv") if !@comp_hash_csv.empty?
  puts "end"
end

def parse_comp_info(file)
  # ("div.row-fluid")
  #   ("div.panel-body")
  #     ("h1.cmp_title").text=>comp_header
  # ('div')[]
  #   if .text == "Положение"
  #     css('a')[0]['href']=>comp_polozh
  #   elsif .text == "Результаты"
  #     css('a')[0]['href']=>comp_result
  #   else
  #     .text=>comp_info
  hash_str = ''
  doc = Nokogiri::HTML(open(file), nil, 'Windows-1251').css('div.row-fluid')


  # save results
  comp_result_ajax = doc.css("div a[rel]")
  comp_result_ajax.each do |elem|
    comp_type = elem.text.delete(',').gsub('/', '. ')
    puts comp_type
    discipline_id = elem['rel']
    comp_id = @comp_id.split(';')[-1]
    html_result = get_html_results(comp_id, discipline_id)
    filename = "#{comp_id}_#{discipline_id}_#{comp_type}.html"
    save_to_file("#{@res_path}/#{filename}", html_result)
  end
  return

  # parse about
  comp_info_body = doc.css('div.panel-body')
  comp_title = comp_info_body.css('h1.cmp_title').text
  # puts comp_title.encoding
  hash_str += "#{@comp_id};title;#{comp_title};"
  comp_info_arr = doc.css("div[style]")
  begin
    result_link_arr = []
    polozh_link_arr = []
    doc_i = 0
    comp_info_arr.each do |elem|
      # puts elem.text
      link = elem.css('img')[0]
      if !link
        info = elem.text.split(":")
        if info.size > 2
          puts info
        end
        info = info.map(&:strip).join(";").gsub("http;", "http:")
        # puts info
        hash_str += "#{info};" if !info.empty?
      else
        link = elem.css('a')[0]
        doc_name = link['href'].to_s.split('/')[-1]
        download_file(link['href'], "#{@doc_path}/#{@comp_id.split(';')[-1]}-#{doc_i}_#{doc_name}")
        puts link['href']
        doc_i += 1
        # puts link.text
        rem = link.text
        if link.text.include?('Результаты')
          result_link = "#{link['href']}"
          result_link_arr.to_a.append(result_link) if !result_link.empty?
        elsif link.text.include?('Положение')
          polozh_link = "#{link['href']}"
          polozh_link_arr.to_a.append(polozh_link) if !polozh_link.empty?
        else
          puts "[ERR] unknown document #{link.to_s.force_encoding('Windows-1251').encode('utf-8')}"
        end
      end
    end
    fin_res_links = "result_links;-;"
    fin_pol_links = "polozh_links;-;"
    fin_res_links = "result_links;#{result_link_arr.join("\n")};" if !result_link_arr.empty?
    fin_pol_links = "polozh_links;#{polozh_link_arr.join("\n")};" if !polozh_link_arr.empty?
    hash_str += "#{fin_res_links}#{fin_pol_links}"
    # puts hash_str
    memberHash = Hash[*hash_str.split(';')] if !hash_str.empty?
    @about_hash_csv.to_a.append(memberHash) if !memberHash.empty?
  rescue => ex
    puts ex.message
    puts hash_str
  end
  puts "end"

end

def iterate_competitions
  @res_hash_csv = []
  @about_hash_csv = []
  comp_counter = 0
  files = Dir.glob("#{@path}**/*.html")
  files.each do |file|
    @comp_id = "id;#{file.split("/")[-1].split(".")[0]}"
    comp_counter += 1
    puts "\t[INFO] #{comp_counter}/#{files.size}: обрабатываю #{file}"
    parse_comp_info(file)
    # break
  end
  # create_csv_from_hash_with_headers(@about_hash_csv, "#{@appDir}/5_about_competition.csv") if !@about_hash_csv.empty?
end

def load_person_pages
  # https://sportcubes.ru/idswim95878
  last_person_id = 95878
  (65755..last_person_id).step(1) do |person_id|
    puts "Обрабатываю #{person_id} из #{last_person_id}"
    person_url = "#{@site}idswim#{person_id}"
    doc = Nokogiri::HTML(open(person_url)).css('div.container-fluid')

    html_person_card = doc.css('div.panel-body')[0]
    if html_person_card


      person_photo = html_person_card.css('p.text-center img')[0]['src']
      photo_url = "#{@site}#{person_photo}"
      photo_name = "#{person_id}.#{person_photo.split('/')[-1].split('.')[-1]}"
      download_file(photo_url, "#{@photo_path}/#{photo_name}") if !photo_url.include?("nofoto.jpg")


      html_person_results = doc.css('div.col-md-9')
      # panel = doc.search('div.panel-info')
      # panel.remove
      html_person_results.search('div.panel').remove
      html_person_results.search('center').remove
      doc_for_save = "#{html_person_card}\n#{html_person_results}"
      save_to_file("#{@person_path}/#{person_id}.html", doc_for_save)
    else
      puts "[ERR] person #{person_id} not found at #{person_url}"
    end
  end
end

def parse_person_info(file)
  res_hash_csv = []
  doc = Nokogiri::HTML(open(file), nil, 'Windows-1251')
  return if !doc.at_css('div.panel-body')

  person_info_doc = doc.css('div.panel-body')
  # p Encoding.list.map(&:names)
  coaches = 'Тренеры;'
  doc.css("div.panel-body > text()").each {
      |elem| coaches += "#{elem.text.delete("\t\n\r")}," if !elem.text.delete("\t\n\r").empty?
  }
  coaches = coaches.split(',').join(',')
  person_name = "Имя;#{person_info_doc.css('span')[0].text.strip}"

  person_info_arr = person_info_doc.css('p')
  city = person_info_arr[0].text.strip.split(': ').join(';')
  city = city.empty? ? '-' : city
  person_city = "Город;#{city}"
  person_age = person_info_arr[1].text.strip.split(': ').join(';')
  person_achievement = person_info_arr[2].text.strip.split(': ').join(';')
  photo = person_info_arr[3].css('img')[0]['src']
  photo_url = photo.include?('nofoto.jpg') ? '-' : "https://sportcubes.ru/#{photo}"
  photo_name = photo_url.include?('-') ? '-' : "#{@person_id.split(';')[-1]}.jpeg"
  # download_file(photo_url, "#{@path}/#{photo_url.split('/')[-1]}") if !photo.include?('-')
  person_photo = "Фото;#{photo_name}"

  person_school = person_info_arr[4].text.strip.split(': ').join(';')

  # puts "#{person_name};#{person_city};#{person_age};#{person_achievement};#{person_photo};#{person_school};#{coaches}"

  # person_info_doc.css('p').each {|item|
  #   puts "\t#{decode_from_cp1251_to_utf8(item.inner_html)}"
  #   puts item.text.strip.split(': ').join(';')
  # }

  doc.css("div[class='col-md-9 col-sm-8']").css('div div').each {|node|
    node.remove
    break
  }
  person_results_div = doc.css("div[class='col-md-9 col-sm-8']").css('div div')
  person_results_table = doc.css("div[class='col-md-9 col-sm-8']").css('table')


  if person_results_table.count > 0
    i = 1
    # puts person_results_div.count, person_results_table.count

    person_results_table.each {|comp|
      comp_title = person_results_div[i - 1].text
      comp_url = person_results_div[i - 1].at_css('a')['href']
      comp_id = comp_url.split('=')[-1]
      comp_place = person_results_div[i].text
      # puts "Title: #{i - 1} - #{comp_title}"
      # puts "Place: #{i} - #{comp_place}"
      # puts "Results: #{i} - #{decode_from_cp1251_to_utf8(comp.inner_html.to_s)}"
      table_row = comp.css('tr')
      row_count = 0
      table_row_header = []
      table_row.each do |row|
        row_count += 1
        if row.text.include?('Дистанция')
          table_row_header = row.css('th').map(&:text)
          # puts table_row_header.join(';')
        else
          table_row_data = row.css('td').map(&:text).map(&:strip)
          # .map{|cell| cell[0..-6]}
          # puts table_row_data.join(';')
          combine_arr = []
          begin
            combine_arr = table_row_header.zip(table_row_data)
            combine_arr = combine_arr.map {|elem1| elem1.map {|elem2| elem2.empty? ? "-" : elem2}}
            hash_str = "comp_id;#{comp_id};comp_url;#{comp_url};Название;#{comp_title};Место;#{comp_place};#{combine_arr.join(";")}"
            memberHash = Hash[*hash_str.split(";")] if !hash_str.empty?
            puts "results: #{memberHash.count}" if memberHash.count != 7
            res_hash_csv.to_a.append(memberHash) if !memberHash.empty?
              # puts 1
          rescue => ex
            puts "[DEBUG] #{hash_str}"
            puts "\t[ERR] #{ex.message}"
          end
        end
      end
      i += 2
    }
  end
  begin
    hash_str = "#{@person_id};#{@user_url};#{person_name};#{person_city};#{person_age};#{person_achievement};#{person_photo};#{person_school};#{coaches[0..-1]}"
    memberHash = Hash[*hash_str.split(";")] if !hash_str.empty?
    memberHash['Результаты'] = res_hash_csv #if !res_hash_csv.empty?
    puts "info: #{memberHash.count}" if memberHash.count != 10
    @about_hash_csv.to_a.append(memberHash) if !memberHash.empty?
  rescue => ex
    puts "[DEBUG] #{hash_str}"
    puts "\t[ERR] #{ex.message}"
  end
  # puts 'end'
end


def iterate_files(path)
  @about_hash_csv = []
  counter = 0
  files = Dir.glob("#{path}**/*.html")
  files.each do |file|
    @person_id = "person_id;#{file.split("/")[-1].split(".")[0]}"
    @user_url = "person_url;https://sportcubes.ru/idswim#{file.split("/")[-1].split(".")[0]}"
    counter += 1
    puts "\t[INFO] #{counter}/#{files.size}: обрабатываю #{file}" if counter % 5000 == 0
    # break if counter > 800
    parse_person_info(file)
  end
  json = Utils.convert_hash_to_json(@about_hash_csv)
  # puts json
  save_to_file("I:/dev_temp/sportcubes.json", json)
  # Utils.create_csv_from_hash_with_headers(@about_hash_csv, "#{@appDir}/person_info.csv") if !@about_hash_csv.empty?
end

def write_to_db
  data = Utils.read_json_file("#{@json_file_path}")
  require './models/sportcubes_model.rb'
  i = 0
  data.each do |elem|
    i += 1
    # puts "#{i} из #{data.count} #{elem['Имя']}" if i % 1000 == 0
    user = User.where('name = ? AND age = ?', elem['Имя'], elem['Возраст'])
    begin
      # if user.exists?
      #   # p "#{user.first.name} существует"
      #   if !(user.first.competitions.find_by(name: :row['Протокол']))
      #     user.first.competitions.create(
      #         comp_id: elem['id'],
      #         name: elem['Протокол'],
      #         discipline: elem['Дисциплина'],
      #         result: elem['Результат'],
      #         result_place: elem['Место']
      #     )
      #   end
      # else
      user = User.create(
          person_id: elem['person_id'],
          person_url: elem['person_url'],
          name: elem['Имя'],
          city: elem['Город'],
          age: elem['Возраст'],
          achievement: elem['Разряд'],
          photo: elem['Фото'],
          school: elem['Спортшкола'],
          coach: elem['Тренеры']
      )
      elem['Результаты'].each {|comp|
        comp_db = user.competitions.where('comp_id = ?', comp['comp_id'])
        if !comp_db.exists?
          user.competitions.create(
              comp_id: comp['comp_id'],
              comp_url: comp['comp_url'],
              title: comp['Название'],
              discipline: comp['Дистанция'],
              result: comp['Результат'],
              result_place: comp['Разряд'],
              country: comp['country'],
              city: comp['city'],
              length: comp['length'],
              date: comp['date']

          # city_info: comp['Место проведения'],
          # fina_scores: comp['Очки FINA'],
          # info_src_url: comp['Источник'],
          # protocol_url: comp['result_links'],
          # polozhenie_url: comp['polozh_links']
          )
        end
      }
    end
  rescue => ex
    puts "\n\t#{i} из #{data.count} #{elem['Имя']}}"
    puts "\n\t[ERR] #{ex.message}"
  end

end

def update_db
  require './models/sportcubes_model.rb'
  comps = Competition.where(comp_url: nil)
  comps.each {|comp|
    begin
      comp.update(comp_url: "https://sportcubes.ru/?page=competitions&c=#{comp.comp_id}")
    rescue => ex
      puts "\n\t#{i} из #{comp.comp_id} }"
      puts "\n\t[ERR] #{ex.message}"
    end
  }
  # comps = Competition.where(country: nil)
  # begin
  #   comps.update_all(country: 'Россия')
  #   puts comps.count
  #   puts "end"
  # rescue => ex
  #   puts "\n\t#{i} из #{comps.count} }"
  #   puts "\n\t[ERR] #{ex.message}"
  # end

end



def update_db2
  data = Utils.read_csv_file('Z:/WorkSpace/Ruby/sport_parser_a/assets/sportcubes/final_about_competition.csv')
  require './models/sportcubes_model.rb'
  i = 0
  data.each {|comp|
    begin
      comp_db = Competition.where(comp_id: comp['id'])
      if comp_db.count > 0
        # puts comp_db.count
        # comp_db.update_all(
        #     city_info: comp['Место проведения'],
        #     fina_scores: comp['Очки FINA'],
        #     info_src_url: comp['Источник'],
        #     protocol_url: comp['result_links'],
        #     polozhenie_url: comp['polozh_links']
        # )
      else
        Competition.create(
            comp_id: comp['id'],
            title: comp['title'],
            date: comp['Даты проведения'],
            city_info: comp['Место проведения'],
            fina_scores: comp['Очки FINA'],
            info_src_url: comp['Источник'],
            protocol_url: comp['result_links'],
            polozhenie_url: comp['polozh_links']
        )
      end
    rescue => ex
      puts "\n\t#{i} из #{data.count} }"
      puts "\n\t[ERR] #{ex.message}"
    end
  }
end

def fix_data
  data = Utils.read_json_file("#{@json_file_path}")
  data.map {|elem|
    elem['Результаты'].map {|comp|
      comp.each {|k, v|
        comp[k] = Utils.remove_whitespaces(v)
      }
      # res = comp['Место'].split(',')
      # if res.count == 3
      #   # puts "#{res[0].split(' ')[-1]} - #{res[1]} - #{res[2]}"
      #   comp['city'] = res[0].split(' ')[-1]
      #   comp['length'] = res[1]
      #   comp['date'] = res[2]
      # elsif res.count == 4
      #   # puts "#{res[0].split(' ')[-1]},#{res[1]} - #{res[2]} - #{res[3]}"
      #   comp['city'] = res[0].split(' ')[-1]
      #   comp['country'] = res[1]
      #   comp['length'] = res[2]
      #   comp['date'] = res[3]
      # else
      #   puts "#{elem['Имя']} #{elem['person_url']} #{comp['Место']}"
      # end
      # comp.delete('Место')
    }
  }
  Utils.create_json_from_hash(data, 'I:/dev_temp/sportcubes/sportcubes_fix.json')
end



@appDir = 'assets/sportcubes'
@doc_path = "#{@appDir}/documents"
@person_path = "#{@appDir}/persons"
@person_path = "#{@appDir}/test_person"
@photo_path = "#{@appDir}/photo"
@path = "#{@appDir}/comp_page"
@res_path = "#{@appDir}/results"
@path = "#{@appDir}/download"
@path = 'I:/dev_temp/photo/'
@site = 'https://sportcubes.ru/'
@person_path = 'I:/dev_temp/persons'
@json_file_path = 'I:/dev_temp/sportcubes/sportcubes.json'

# get_competitions
# iterate_competitions
# load_person_pages
# iterate_files(@person_path)
# write_to_db
# update_db
# fix_data