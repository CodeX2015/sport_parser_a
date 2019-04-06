require_relative 'utils/utils.rb'

require 'open-uri'
require 'nokogiri'

@site = 'http://www.gymnastics.sport/'

def get_members_from_site(url)
  # получаем список участников из файла
  doc = Nokogiri::HTML(open(url)).css('.table')
  links = doc.css('a[href]')
  i = 0
  links.each do |link|
    i += 1
    profile_url = ''
    site = "#{@site}site"
    profile_url = site + (link['href'])[2..-1] + '#results'
    puts "#{i} from #{links.count} member: #{link.text} profile_url: #{profile_url}"
    path = "assets/members/#{link.text}.html"

    if File.exist?(path)
      puts("[WARN] #{path} already exist")
      next
    end

    sub_doc = nil
    loop do
      begin
        sub_doc = Nokogiri::HTML(open(profile_url, read_timeout: 30))
        File.write(path, sub_doc)
      rescue => ex
        puts "ERROR #{ex.message}"
        sub_doc = nil
      end
      break if !sub_doc.nil?
    end
    # puts "next"
  end
  # puts 'end of script'
end

def download_member_photo(url, path)
  if url =~ /\A#{URI::regexp(['http', 'https'])}\z/
    if !File.exist?(path)
      loop do
        begin
          puts "[INFO] download #{url} to #{path}"
          IO.copy_stream(open(url), path)
          break
        rescue :ex
          puts "[ERR] #{ex.message}"
        end
      end
    else
      puts("[WARN] #{path} already exist")
    end
    #file_path = "#{Dir.pwd}#{path}#{download.base_uri.to_s.split('/')[-1]}"
    # File.exist?(path) ? puts("[WARN] #{path} already exist") : IO.copy_stream(download, path)
  else
    puts("[WARN] wrong url #{url}")
  end
end

def save_biography_to_file(member_id, biography)
  path = "assets/biography/#{member_id}.html"
  if !File.exist?(path)
    begin
      File.write(path, biography)
    rescue => ex
      puts "[ERR] #{ex.message}"
    end
  else
    puts("[WARN] #{path} already exist")
  end
end

def parse_member_results_2(file)
  # get results block
  if html.at_css('div#results')
    member_results = html.css('div#results')
    events = member_results.css("div[class='panel panel-info']")
    event_i = 0
    events.each do |event|
      event_i += 1
      @event_name = event.css("a[data-parent='#results']").text.delete("\n\r").strip.gsub(/ +/, " ")

      puts "#{event_i} from #{events.count} event: #{@event_name}"
      event_types = event.css("div[class='panel panel-default']")
      event_type_i = 0
      event_types.each do |event_type|
        event_type_i += 1

        @event_type_name = event_type.css("div[class='panel-heading']").text.delete("\n\r").strip.gsub(/ +/, " ")
        puts "\t#{event_type_i} from #{event_types.count} event_type: #{@event_type_name}"

        ranks = event_type.css("div[class='col-md-6 col-xs-12']")
        rank_result = ''
        @all_ranks = ''
        ranks.each do |rank|
          rank_type = rank.css('div.col-xs-6')[0].text.delete("\n\r").strip.gsub(/ +/, " ")
          rank_score = rank.css('div.col-xs-6')[1].text.delete("\n\r").strip.gsub(/ +/, " ")
          puts "\t\t#{rank_type}: #{rank_score}"
          @all_ranks += "#{rank_type};#{rank_score};"
          # rank_result = {rank_type: rank_type, rank_result: rank_result}
          # all_ranks.to_a.append(rank_result) if !rank_result.empty?
        end

        memberHash = {member_name: @member_name, identity: @identity_result,
                      member_id: @photo_id, accounts: @accounts_result,
                      member_photo: @photo_file_name, event: @event_name,
                      event_type: @event_type_name, all_ranks: @all_ranks}
        @hash_csv.to_a.append(memberHash) if !memberHash.empty?
      end
    end
  end
end

def parse_member_results(file)
  html = Nokogiri::HTML(open(file))

  # get id
  if html.at_css('td#photo')
    img = html.css('td#photo').css('img.img-polaroid')[0]
    @member_id = File.basename(img['src']).split('_')[-1]
    puts "\tmember_id: #{@member_id}"
  end

  member_results = html.css('div#results')
  events = member_results.css("div[class='panel panel-info']")
  event_i = 0
  events.each do |event|
    event_i += 1
    event_name = event.css("a[role='button']").text.delete("\n\r").strip.gsub(/ +/, " ")
    puts "#{event_i} from #{events.count} event: #{event_name}"
    event_types = event.css("div[class='panel panel-default']")
    event_type_i = 0
    event_types.each do |event_type|
      event_type_i += 1
      event_type_name = event_type.css("div[class='panel-heading']").text.delete("\n\r").strip.gsub(/ +/, " ")
      puts "\t#{event_type_i} from #{event_types.count} event_type: #{event_type_name}"
      ranks = event_type.css("div[class='col-md-6 col-xs-12']")

      rank_result = ''
      ranks.each do |rank|
        rank_data = rank.css('div.col-xs-6')
        rank_type = rank_data[0].text.delete("\n\r").strip.gsub(/ +/, " ")
        rank_score = rank_data[1].text.delete("\n\r").strip.gsub(/ +/, " ")
        rank_result += "#{rank_type};#{rank_score};"
        puts "\t\trank_type: #{rank_type} \n\t\trank_score: #{rank_score}"
      end
      puts "rank_result:#{rank_result[0..-2]}"
      memberHash = {member_name: @member_name, member_id: @member_id,
                    event: event_name, event_type: event_type_name, rank: rank_result}
      @hash_csv.to_a.append(memberHash) if !memberHash.empty?
    end
  end
end

def parse_member_info(file)

  html = Nokogiri::HTML(open(file))

  # if html.at_css('td#photo')
  #   img = html.css('td#photo').css('img.img-polaroid')[0]
  #   photo_url = File.basename(img['src'])
  #   @photo_id = photo_url.split('_')[-1]
  # end
  # # get identity block
  # if html.at_css("div[class='panel panel-primary']")
  #   member_identity = html.css("div[class='panel panel-primary']")
  #   @identity_result = ''
  #   identity_params = member_identity.css("div[class='col-md-12 col-xs-12']")
  #   identity_params.each do |param|
  #     begin
  #       identity_header = param.css("div[class='col-xs-6 col-md-3 text-left']")[0].inner_text.delete("\n\r").strip.gsub(/ +/, " ")
  #       identity_data = param.css("div[class='col-xs-6 col-md-3 text-left']")[1].text.delete("\n\r").strip.gsub(/ +/, " ")
  #       puts "#{identity_header}: #{identity_data}"
  #       @identity_result += "#{identity_header};#{identity_data};"
  #     rescue
  #     end
  #   end
  # end
  #
  # memberHash = {member_name: @member_name, member_id: @photo_id, identity: @identity_result}
  # @hash_csv.to_a.append(memberHash) if !memberHash.empty?
  #
  # return

  # get photo
  if html.at_css('td#photo')
    img = html.css('td#photo').css('img.img-polaroid')[0]
    photo_url = File.basename(img['src'])
    @photo_id = photo_url.split('_')[-1]
    @photo_file_name = "#{@photo_id}.jpg"
    # puts img['src'], photo_url, photo_name
    download_member_photo("#{@site}/#{photo_url}", "#{Dir.pwd}/assets/photo/#{@photo_file_name}")
  end

  # get identity block
  if html.at_css("div[class='panel panel-primary']")
    member_identity = html.css("div[class='panel panel-primary']")
    identity_params = member_identity.css("div[class='col-md-6 col-xs-12']")
    @identity_result = ''
    identity_params.each do |param|
      identity_header = param.css("div[class='col-xs-6 text-left']")[0].text
      identity_data = param.css("div[class='col-xs-6 text-left']")[1].text
      puts "#{identity_header}: #{identity_data}"
      @identity_result += "#{identity_header};#{identity_data};"
    end
    identity_params = member_identity.css("div[class='col-md-12 col-xs-12']")
    identity_params.each do |param|
      begin
        identity_header = param.css("div[class='col-xs-6 col-md-3 text-left']")[0].inner_text.delete("\n\r").strip.gsub(/ +/, " ")
        identity_data = param.css("div[class='col-xs-6 col-md-3 text-left']")[1].text.delete("\n\r").strip.gsub(/ +/, " ")
        puts "#{identity_header}: #{identity_data}"
        @identity_result += "#{identity_header};#{identity_data};"
      rescue :ex
        puts "[ERR] #{ex.message}"
      end
    end
  end


  # get biography block
  if html.at_css('div#info')
    member_info = html.css('div#info')

    # get account info
    accounts = member_info.css("div[class='container-fluid']").css("div[class='col-md-6 col-xs-12']")
    account_i = 0
    # puts accounts.count
    @accounts_result = ''
    accounts.each do |account|
      account_i += 1
      account_header = account.css("div[class='col-xs-6 text-left']")[0].text
      account_url = account.css("div[class='col-xs-6 text-left']")[1].css('a[href]')[0]
      puts "Account #{account_i} from #{accounts.count} #{account_header}: #{account_url['href']}"
      @accounts_result += "#{account_header};#{account_url['href']};"
    end

    # get account moreInfo
    @biography_data = member_info.css('div#moreInfo').inner_html
    puts "biography:\n#{@biography_data.strip.gsub(/ +/, " ")}"
  end

  memberHash = {member_name: @member_name, identity: @identity_result,
                member_id: @photo_id, member_photo: @photo_file_name,
                accounts: @accounts_result}
  save_biography_to_file(@photo_id, @biography_data) if !@biography_data.to_s.empty?
  @hash_csv.to_a.append(memberHash) if !memberHash.empty?
end

def parse_members
  files = Dir.glob('assets/members/*.html')
  files_i = 0
  files.each do |member|
    files_i += 1
    puts "\nParse file #{files_i} from #{files.count}"
    @member_name = File.basename(member, ".*")
    puts "\tmember: #{@member_name}"
    # parse_member_results(member)
    parse_member_info(member)
    # break
  end
end


def load_members
  Dir.glob('assets/src/*.html') do |file|
    get_members_from_site(file)
  end
end

# load_members
# exit

@hash_csv = []
parse_members
Utils.create_csv_from_hash(@hash_csv)
# sub_doc = Nokogiri::HTML(open('assets/1_1.html'))
# parse_member(sub_doc)