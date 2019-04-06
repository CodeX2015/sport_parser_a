require 'open-uri'
require 'nokogiri'

$download_path = "E:\\Ruby\\WorkSpace\\downloads\\2016\\"

def get_path_by_url(url)
  path = url.split('/').last
  return "#{$download_path}#{path}\\"
end

def download_file(url, path)
  begin
    url = url.split('?')[0] if url.include?('?')
    if url =~ /\A#{URI::regexp(['http', 'https'])}\z/
      download = open(url)
      puts "#{path}#{download.base_uri.to_s.split('/')[-1]}"
      file_path = path + download.base_uri.to_s.split('/')[-1]
      File.exist?(file_path) ? puts('file already exist') : IO.copy_stream(download, file_path)
      # IO.copy_stream(download, file_path) if !File.exist?(file_path)
    else
      puts("bad url #{url}")
    end
  rescue => ex
    puts ex.message
  end
end

def parse_files(url)
  puts "Parsing files processing..."
  url.to_s.include?('/forum/') ? parse_forum(url) : parse_news(url)
end

def parse_news(url)
  puts "Parsing news processing..."
  begin
    download_path = get_path_by_url(url)
    puts download_path
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
    set_path_by_url(url)

    page = Nokogiri::HTML(open(url.to_s))
    forum = page.css(".gTable")
    forum.css("img[src]").each do |img|

      # debuging info
      puts img['src'] if !img['src'].include?('s106.ucoz.net') &&
          !img['src'].include?("rg4u.clan.su/imgr/") &&
          !img['src'].include?("rg4u.clan.su") &&
          img['src'].include?("http")

      download_file(img['src'], download_path) if !img['src'].include?('s106.ucoz.net') &&
          !img['src'].include?("rg4u.clan.su/imgr/") &&
          !img['src'].include?("rg4u.clan.su") &&
          img['src'].include?("http")

    end
  rescue => ex
    puts ex.message
  end
end

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
        puts "    #{td.text.delete('↑').strip}" if td.text && !td.text.strip.empty?
      end
      if tr.css('a[href]')
        tr.css('a').each do |link|
          puts "    ссылка=#{link_i}"
          link_i += 1
          # puts link
          # puts link["title"][0].text
          puts "      #{link['href'].strip}"
          parse_files(link['href'].strip)
        end
      end
    end
    # break if tr_i == 8
  end
end

parse_calendar('http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_2016.htm')


# def get_links_calendar_by_year(url)
#   page = Nokogiri::HTML(open(url.to_s))
#   forum = page.css("font[color='#800000']")
#   forum.css("a[href]").each do |link|
#     puts link['href'] if link['href'].include?('tournaments/RU/List_IRGT_RU')
#     # parse_calendar(link) if link['href'].include?('tournaments/RU/List_IRGT_RU')
#   end
# end
# get_links_calendar_by_year('http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_2018.htm')

