# require 'mechanize'
require 'nokogiri'
require 'open-uri'
require_relative 'utils/utils.rb'
# coding: cp866 Encoding.default_external = Encoding::CP866 Encoding.default_internal = Encoding::CP866
# encoding: utf-8


def create_directory(dir_name)
  Dir.mkdir(dir_name) unless File.exists?(dir_name)
end

def move_file(file, dst)
  require 'fileutils'
  FileUtils.mv(file, dst)
end

def post_request(sport_url, page_number)
  require 'net/http'
  require 'openssl'

  # secret = 'your-secret-key'
  # api_key = 'your-api-key'

  uri = URI(sport_url)
  http = Net::HTTP.new(uri.host)
  request = Net::HTTP::Post.new(uri.request_uri)
  form_data = URI.encode_www_form(action: 'list', need: 'items', search_query_form: '1', page: page_number)
  request.body = form_data
  # request.add_field('Key', api_key)
  # request.add_field('Sign', OpenSSL::HMAC.hexdigest( 'sha512', secret, form_data))

  return http.request(request)
end

def get_coach_links(sport_url, filepath)
  final_result = []
  page_number = 1

  loop do
    # https://zoon.ru/msk/p-trener/?action=list&need%5B%5D=items&search_query_form=1&page=1
    # https://zoon.ru/msk/p-trener/vitalij_olegovich_polonnikov/
    req_res = post_request(sport_url, page_number)
    coaches_html = Nokogiri::HTML(req_res.body).css('li.prof-item')
    if coaches_html.count.zero?
      puts "#{page_number - 1} pages"
      break
    end
    coaches_links = coaches_html.css('div.clearfix').css('a[data-js-lnk]').map {|element| element['data-js-lnk']}
    page_number += 1
    final_result += coaches_links
  end

  final_result.each do |elem|
    puts elem
  end

  File.open(filepath, 'w+') do |f|
    f.write final_result.join("\n")
  end

  puts 'end get_coach_links'
end


def download_page_from_site(url)

  if url =~ /\A#{URI::regexp(['http', 'https'])}\z/
    # получаем список участников из файла
    page = open(url.to_s)
    doc = Nokogiri::HTML(page).css('div.js-scroll-main')
    return doc
  else
    puts("[WARN] wrong url #{url}")
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
      # puts("[WARN] #{path} already exist")
    end
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

def get_zoon_links
  file = File.read("#{@appDownload}zoon_links.txt")
  doc = Nokogiri::HTML(file)
  links = doc.css('a')
  links.each do |link|
    puts "url=#{link['href']}, title=#{link['title']}"
    create_directory("#{@appDownload}#{link['title']}")
    filepath = "#{@appDownload}#{link['title']}/#{link['title'].gsub(" ", "_")}.txt"
    get_coach_links(link['href'], filepath)
  end
  puts 'end get_zoon_links'
end

def load_coaches
  coach_counter = 0
  files = Dir.glob("#{@appDownload}**/*.txt")
  files.each do |file|
    puts file
    urls = File.readlines(file)
    urls.each do |url|
      coach_counter += 1
      url = url.delete("\n")
      doc = download_page_from_site(url)
      continue if doc.nil?
      name = url.split('/')[-1]
      path = "#{File.dirname(file)}/#{name}.html"
      puts "#{coach_counter} - сохраняю #{url} в #{path}"
      save_to_file(path, doc)
    end
  end
  puts "#{coach_counter} тренеров обработал"
end

def parse_coach_info(file)
  # html_file = File.open(file, "r")
  # html_from_file = html_file.read
  # html_file.close
  # #encode_text = text_file.force_encoding('Windows-1251')
  # html = Nokogiri::HTML(html_from_file, nil, Encoding::UTF_8.to_s)

  @identity_result = ''
  html = Nokogiri::HTML(open(file), nil, "utf-8")


  # get photo
  photo_file_name = "-"
  if html.at_css("div[class='prof-photo pull-left ']")
    img = html.css("div[class='prof-photo pull-left ']")[0]
    photo_url_arr = URI.extract(img['style'].split('(')[-1].gsub('\');', ''))
    photo_url = photo_url_arr[0].to_s

    source_id = "#{File.basename(file, '.html')}"
    @identity_result += "source_id;#{source_id};source_url;https://zoon.ru/msk/p-trener/#{source_id}/;"
    photo_file_name = "#{File.basename(file, '.html')}.jpg"
    photo_file_path = "#{File.dirname(file)}/"
    # puts "[INFO] url=#{photo_url}, path=#{photo_file_path}#{photo_file_name}"
    # download_photo("#{photo_url}", "#{photo_file_path}#{photo_file_name}")
  end
  @identity_result += "coach_photo;#{photo_file_name};"

  coach_name = '-'
  coach_name = html.at_css("h1[class='prof-name H1 m0']").text
                   .gsub(';', '.').strip if html.at_css("h1[class='prof-name H1 m0']")
  coach_phone = '-'
  coach_phone = html.at_css('span.js-phone')['data-number']
                    .gsub(';', '.').strip if html.at_css('span.js-phone')
  # coach_phone = html.at_css("span[class='js-phone']")['data-number']
  # .gsub(';', '.').strip if html.at_css("span[class='js-phone']")
  coach_rating = '-'
  coach_rating = html.at_css('span.stars-total-rating').text
                     .gsub(';', '.').strip if html.at_css('span.stars-total-rating')

  # puts "[INFO] name:\n\t#{coach_name}\nphone:\n\t#{coach_phone}\nrating:\n\t#{coach_rating}"

  coach_comment = '-'
  if html.at_css("div[class='pull-left comments gray js-goto-comments']")
    coach_comment = html.at_css("div[class='pull-left comments gray js-goto-comments']")
                        .text.strip.delete("\t").delete("\n\r").gsub(';', '.')
    # puts "[INFO] comment:\n\t#{coach_comment}"
  end
  @identity_result += "coach_name;#{coach_name};coach_phone;#{coach_phone};coach_rating;#{coach_rating};coach_comment;#{coach_comment};"

  # get identity block
  if html.at_css('div.btop')
    begin
      identity_params = html.css('dl.fluid')
      information = {'Информация': '-', 'Специальность': '-', 'Специализация': '-', 'Образование': '-',
                     'Опыт и достижения': '-', 'Район': '-', 'Место приема': '-', 'Цена:': '-', 'Сертификаты и документы': '-'}
      identity_params.each do |param|

        identity_header = param.css('dt')[0].text
                              .strip.delete("\t").gsub(';', '.')
        identity_body = ''
        if param.at_css('dd.simple-text')
          param_body = param.css('dd.simple-text')
          if param_body.at_css('div.oh li[data-src]')
            # puts "PICS: #{identity_header}"
            # ('li.data-src')[]
            # li['data-src']=>pics
            param_pics = param_body.css('div.oh li[data-src]')
            param_pics.each do |pic|
              # puts "pic #{pic['data-src']}"
              identity_body += "#{pic['data-src'].strip.delete("\t\n\r").gsub(';', '.')}\n"
            end
            # identity_body = identity_body.chomp
          elsif param_body.at_css("div.block-group")
            # puts "[INFO] #{identity_header}"
            param_list_elem = param_body.css("div[class='block-group mg-top-xs']")
            param_list_elem.each {|elem|
              # puts "\t- #{elem.text.strip.delete("\t")}"
              identity_body += elem.text
                                   .strip.delete("\t\n\r").gsub(';', '.')
            }
          else
            # identity_body = Utils.remove_whitespaces(param_body.inner_html.to_s.gsub('<br>', ' '))
            #                       .strip.delete("\t").delete("\n\r")
            #                       .gsub('Показать все', '').gsub(';', '.')
            # puts test
            identity_body = param_body.text
                                .strip.delete("\t")
                                .gsub("\n\r", ' ')
                                .gsub('Показать все', '').gsub(';', '.')
                                .gsub(/\:(?![ ])/, ': ').gsub(/\.(?![ ])/, '. ')
                                .gsub(/(?<=[a-z]|[а-я])(?=[A-Z]|[А-Я])/, ' ')
            # puts identity_body
          end
        else
          identity_body = param.css("dd")[0].text
                              .delete("\t").delete("\n\r")
        end
        # puts "[INFO] #{identity_header}:\n\t#{identity_body}"
        information[identity_header] = identity_body.chomp if !identity_body.empty?
      end
      inform_result = information.to_a.join(';')
      @identity_result += "#{inform_result};"

      # coach_jobs
      gym_names = ''
      gym_addresses = ''
      gym_ratings = ''
      gym_comments = ''
      if html.at_css('ul#ProfAddresses')
        coach_jobs = html.css('ul#ProfAddresses li')
        # puts "[INFO] serv_count=#{coach_jobs.size}"
        jobs_result = ''
        coach_jobs.each do |coach_job|
          job_description = coach_job.css('div.service-description')
          gym_name = coach_job.css('div.H3').text
                         .strip.delete("\t\n\r").gsub(';', '.')
          gym_address = coach_job.css('address.invisible-links').text
                            .strip.delete("\t\n\r").gsub(';', '.')
          gym_rating = coach_job.css("div[class='pull-left gray']").text
                           .strip.delete("\t\n\r").gsub(';', '.')
          gym_comment = coach_job.css("div[class='last-comment simple-text rating-offset rel']").text
                            .strip.delete("\t\n\r").gsub(';', '.')
          # puts "[INFO] name:\n\t#{gym_name}\nrating:\n\t#{gym_rating}\ncomment:\n\t#{gym_comment}\naddress:\n\t#{gym_address}"
          gym_names += "#{gym_name}\n" if !gym_name.empty?
          gym_addresses += "#{gym_address}\n" if !gym_address.empty?
          gym_ratings += "#{gym_rating}\n" if !gym_rating.empty?
          gym_comments += "#{gym_comment}\n" if !gym_comment.empty?

        end
      end
      gym_names = gym_names.empty? ? '-' : gym_names.chomp
      gym_ratings = gym_ratings.empty? ? '-' : gym_ratings.chomp
      gym_comments = gym_comments.empty? ? '-' : gym_comments.chomp
      gym_addresses = gym_addresses.empty? ? '-' : gym_addresses.chomp
      @identity_result += "gym_name;#{gym_names};gym_rating;#{gym_ratings};gym_comment;#{gym_comments};gym_address;#{gym_addresses};"
    rescue => ex
      puts "[ERR] #{ex.message}"
    end
  end
  @identity_result.encode('ASCII', 'binary', invalid: :replace, undef: :replace, replace: '')
  # #.encode("utf-8", "cp1251", invalid: :replace, undef: :replace)
  #.force_encoding("utf-8").encode('cp1251')
  #.force_encoding("utf-8").encode("cp1251", undef: :replace)
  args = @identity_result.split(';')
  # puts "args: #{args.size}"

  memberHash = Hash[*(Utils.remove_whitespaces(@identity_result)).split(';')] if !@identity_result.empty?

  @hash_csv.to_a.append(memberHash) if !memberHash.empty?
end

def parse_coaches
  @hash_csv = []
  coach_counter = 0
  files = Dir.glob("#{@appParse}**/*.html")
  files.each do |file|
    coach_counter += 1
    puts "\t#{coach_counter}/#{files.size}: обрабатываю #{file}" if coach_counter % 10 == 0
    begin
      parse_coach_info(file)
    rescue => ex
      puts "[ERR] #{coach_counter}/#{files.size}: обрабатываю #{file} #{ex.message}"
      # move_file(, @appErr)
      # File.chmod(0755, file) rescue nil
      #  File.rename(file, "#{File.path(file)}/#{File.basename(file)}.err")
      # FileUtils.mv file, "#{File.dirname(file)}/#{File.basename(file,'.*')}.err"
    end
    # break if coach_counter == 100
  end
  Utils.create_csv_from_hash_with_headers(@hash_csv, "#{@appDir}/parse_coaches_test.csv") if !@hash_csv.empty?
  Utils.create_json_from_hash(@hash_csv, "#{@appDir}/parse_coaches_test.json") if !@hash_csv.empty?
end

def write_to_db
  data = Utils.read_json_file("I:/dev_temp/zoon/parse_coaches_test.json")
  require './models/zoon_model.rb'
  data.each do |row|
    begin
      # puts "#{row['gym_name']} - #{row['coach_name']}"
      gym = Gym.where('title LIKE ?', "%#{row['gym_name']}%")

      if gym.exists?
        # puts gym.first.coaches.find_by(name: :row['coach_name']).name, row['coach_name']
        if !(gym.first.coaches.find_by(name: row['coach_name']))
          # puts "#{row['gym_name']} существует"
          gym.first.coaches.create(
              photo: row['coach_photo'],
              name: row['coach_name'],
              phone: row['coach_phone'],
              rating: row['coach_rating'],
              comment: row['coach_comment'],
              info: row['Информация'],
              specialty: row['Специальность'],
              specialization: row['Специализация'],
              education: row['Образование'],
              experience: row['Опыт и достижения'],
              area: row['Район'],
              address: row['Место приема'],
              price: row['Цена:'],
              docs: row['Сертификаты и документы'],
              source_id: row['source_id'],
              source_url: row['source_url']
          )
        end
      else
        gym = Gym.create(
            title: row['gym_name'],
            comment: row['gym_comment'],
            rating: row['gym_rating'],
            address: row['gym_address']
        )
        gym.coaches.create(
            photo: row['coach_photo'],
            name: row['coach_name'],
            phone: row['coach_phone'],
            rating: row['coach_rating'],
            comment: row['coach_comment'],
            info: row['Информация'],
            specialty: row['Специальность'],
            specialization: row['Специализация'],
            education: row['Образование'],
            experience: row['Опыт и достижения'],
            area: row['Район'],
            address: row['Место приема'],
            price: row['Цена:'],
            docs: row['Сертификаты и документы'],
            source_id: row['source_id'],
            source_url: row['source_url']
        )
      end
    rescue => ex
      puts row['coach_name'], row['photo_name'], row['source_url']
      puts ex.message
    end
  end

  return

  # Play around!
  gym = Gym.create(name: "Чемпион")
  gym.coaches.create(name: "Max")
  gym.coaches.create(name: "Chai")
  p Gym.first.coaches
end


def convert_to_json
  base_url = 'https://zoon.ru/msk/p-trener/'
  data = Utils.read_csv_file("I:/dev_temp/zoon/parse_coaches.csv")
  data.each {|row|
    id_name = row['photo_name'].split('.')[0]
    row['source_url'] = "#{base_url}#{id_name}/"
    # p id_name
  }
  Utils.create_json_from_hash(data, "I:/dev_temp/zoon/coaches.json")
end

def main
  #get_zoon_links
  #load_coaches
  #
  # parse_coaches
  # return

  # Dbutils.get_from_db
  #   require './models/zoon_model.rb'
  #   gym = Gym.create(name: "Чемпион")
  #   gym.coaches.create(name: "Max")
  #   gym.coaches.create(name: "Chai")
  #   p Gym.find_by(name: :'Чемпион').coaches
  # return

  # convert_to_json
  # return

  # 
  write_to_db

  return
end


@appDir = 'assets/zoon/'
@appDir = 'D:/!PARSE_STORAGE/assets/zoon/'
@appDir = 'I:/dev_temp/zoon/'
@appDownload = "#{@appDir}download/"
@appErr = "#{@appDir}error/"
@sppDone = "#{@appDir}done/"
@appParse = "#{@appDir}parse/"
@appParse = "#{@appDir}test/"
main

# base_url = 'https://zoon.ru/msk/p-trener/'
#
# mechanize = Mechanize.new
#
# page = mechanize.get(base_url)
#
# link = page.(class: 'js-next-page')
#
# page2 = link.click
#
# puts page.title
