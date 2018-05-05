require 'open-uri'
require 'nokogiri'
$year = '2015'
$download_path = "E:\\Ruby\\WorkSpace\\downloads\\#{$year}\\"
$file_path = nil

def set_path_by_url(url)
  path = url.split('/').last
  $file_path = "#{$download_path}#{path}\\"
end

def download_file(url)
  begin
    url = url.split('?')[0] if url.include?('?')
    if url =~ /\A#{URI::regexp(['http', 'https'])}\z/
      Dir.mkdir($download_path) if !Dir.exist?($download_path)
      Dir.mkdir($file_path) if !Dir.exist?($file_path)
      download = open(url)
      puts "#{$file_path}#{download.base_uri.to_s.split('/')[-1]}"
      file_path = $file_path + download.base_uri.to_s.split('/')[-1]
      File.exist?(file_path) ? puts('file already exist') : IO.copy_stream(download, file_path)
      # IO.copy_stream(download, file_path) if !File.exist?(file_path)
    else
      puts("bad url #{url}")
    end
  rescue => ex
    puts ex.full_message
  end
end

def parse_news(url)
  puts "Parsing news processing..."
  begin
    download_path = get_path_by_url(url)
    Dir.mkdir(download_path) if !Dir.exist?(download_path)

    page = Nokogiri::HTML(open(url.to_s))
    td = page.css(".eMessage")
    td.css("img[src]").each do |img|
      puts img['src']
      download_file(img['src'], download_path)
    end
  rescue => ex
    puts ex.message
  end
end


def parse_forum(url)
  puts "Parsing forum processing..."
  begin
    download_path = get_path_by_url(url)
    Dir.mkdir(download_path) if !Dir.exist?(download_path)

    page = Nokogiri::HTML(open(url.to_s))
    forum = page.css(".gTable")
    forum.css("img[src]").each do |img|

      # debuging info
      puts img['src'] if !img['src'].include?('s106.ucoz.net') &&
          !img['src'].include?("rg4u.clan.su/imgr/") &&
          !img['src'].include?("rg4u.clan.su") &&
          img['src'].include?("http")

      # download_file(img['src'], download_path) if !img['src'].include?('s106.ucoz.net') &&
      #     !img['src'].include?("rg4u.clan.su/imgr/") &&
      #     !img['src'].include?("rg4u.clan.su") &&
      #     img['src'].include?("http")

    end
  rescue => ex
    puts ex.message
  end
end

# if !Dir.exist?(download_path)
#   puts "not exist #{download_path}"
# else
#   puts "exist #{download_path}"
# end

# test = 'http://s106.ucoz.net/img/fr/moder.gif   rg4u.clan.su/imgr/'
# puts test if !test.include?('s106.ucoz.net') || !test.include?("rg4u.clan.su/imgr/")


def parse_files(url)
  puts "Parsing files processing..."
  #puts parse_files('http://rg4u.clan.su/news/2017-11-06-2664')
  url.to_s.include?('/forum/') ? parse_forum(url) : parse_news(url)

  # parse_forum('http://rg4u.clan.su/news/2017-11-16-2691')
  # parse_news('http://rg4u.clan.su/news/sorevnovanija_po_khudozhestvennoj_gimnastike_parad_gracij_26_28_01_2018_saransk_respublika_mordovija/2018-01-04-2779')
end

# parse_files('http://rg4u.clan.su/news/2018-02-18-2960')
# str = 'E:\Ruby\WorkSpace\sport_parser_a\downloads\2017-11-16-2691\83968873.jpg?1'
# str !=~ /\A#{URI::regexp(['http', 'https'])}\z/ ? puts(str)&&return :
# # str =~ /\A#{URI::regexp(['http', 'https'])}\z/ ? puts(str) :
# str=str.split('?')[0]
# puts "error"


def get_links_calendar_by_year(url)
  page = Nokogiri::HTML(open(url.to_s))
  forum = page.css("font[color='#800000']")
  forum.css("a[href]").each do |link|
    puts link['href'] if link['href'].include?('tournaments/RU/List_IRGT_RU')
  end
end

# http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_2011.htm
# http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_2012.htm
# http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_2013.htm
# http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_2014.htm
# http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_2015.htm
# http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_2016.htm
# http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_2017.htm
# http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_2018.htm
#


def parse_post(url)
  puts "Parsing post processing..."
  begin
    download_path = get_path_by_url(url)
    Dir.mkdir(download_path) if !Dir.exist?(download_path)
    post = url.split('/')[-1].split('-')[2]
    page = Nokogiri::HTML(open(url.to_s))
    td = page.css("#post#{post}")
    td.css("img[src]").each do |img|
      puts img['src'] if !img['src'].include?('s106.ucoz.net') &&
          !img['src'].include?("rg4u.clan.su/imgr/") &&
          !img['src'].include?("rg4u.clan.su") &&
          img['src'].include?("http")
      # download_file(img['src'], download_path) if !img['src'].include?('s106.ucoz.net') &&
      #     !img['src'].include?("rg4u.clan.su/imgr/") &&
      #     !img['src'].include?("rg4u.clan.su") &&
      #     img['src'].include?("http")
    end
  rescue => ex
    puts ex.message
  end
end

# parse_calendar('http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_2018.htm')
#
# @str = ['http://rg4u.clan.su/forum/32-187-26616-16-1355225914',
#         'http://rg4u.clan.su/news/2012-10-28-383']
#
# @str.each do |str|
#   puts str
#   str.to_s.match(/(?=\/\d{4}\-\d{2}\-\d{2})/) ? puts("news") : puts("post")
# end
#

def parse_documents(url)
  puts "Parsing documents processing..."
  begin
    set_path_by_url(url)
    page = Nokogiri::HTML(open(url.to_s))
    div = page.css("div[class='info_box document']")
    div.css("a").each do |doc|
      puts "#{doc.text} - #{doc['href']}"
      file_url = doc['href']

      if doc['href'].include?('https://vk.com')
        vk = Nokogiri::HTML(open(doc['href'].to_s))
        frame = vk.css('#iframe')[0]
        puts frame['src']
        file_url = frame['src']
      end
      download_file(file_url) if doc['href'].include?("http")
    end
  rescue => ex
    puts "ERROR #{ex.message}"
  end
end

# parse_documents('http://rg4u.clan.su/news/2017-11-29-2712')

def parse_calendar(url)
  # получаем содержимое веб-страницы в объект
  page = Nokogiri::HTML(open(url.to_s))

# производим поиск по элементам с помощью css-выборки
  table = page.css("table[style='border-collapse: collapse;']")

#puts table
  tr_i = 0

  table.css('tr').each do |tr|
    puts "строка=#{tr_i}"
    td_i = 0
    link_i = 0
    tr_i += 1
    tds = tr.css('td')
    if tds.count == 4
      tds.each do |td|
        puts "  столбец=#{td_i}"

        td_i += 1
        # puts "  #{td.to_html}" if td_i == 4
        # puts "td_test='#{td.text.strip}'" if td_i == 4 and !td.text.strip.empty?
        puts "    #{td.text.delete('↑').strip}" if td.text && !td.text.strip.empty?

        # .css('.myTblTD1')
        # puts 'next'
      end
      #puts tr
      if tr.css('a[href]')
        tr.css('a').each do |link|
          puts "    ссылка=#{link_i}"
          link_i += 1
          # puts link
          # puts link["title"][0].text
          puts "      #{link['href'].strip}"
          if link['href'.strip].to_s.include?("/news/")
            # parse_news(link['href'].strip)
            parse_documents(link['href'].strip)
          else
            # link['href'.strip].to_s.match(/(?=\/\d{2}\-\d{3}\-\d{5}-\d{2})/) ?
            #     parse_post(link['href'].strip) : parse_forum(link['href'].strip)
          end
        end
      end
    end
    #break if tr_i == 25
  end
end

for i in 2015..2015
  puts "Parsing data at #{i}"
  $year = i
  parse_calendar("http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_#{$year}.htm")
end
