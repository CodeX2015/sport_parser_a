require 'open-uri'
require 'nokogiri'
require 'json'

$download_path = "E:\\Ruby\\WorkSpace\\downloads\\2016\\"

def parse_calendar(url)
  # получаем содержимое веб-страницы в объект
  page = Nokogiri::HTML(open(url.to_s))

# производим поиск по элементам с помощью css-выборки
  table = page.css("table[style='border-collapse: collapse;']")


  result = []

  tr_i = 0
  hash_i = 0
  table.css('tr').each do |tr|
    puts "строка=#{tr_i}"
    td_i = 0
    link_i = 0
    tr_i += 1
    tds = tr.css('td')
    data = Hash.new
    if tds.count == 4
      tds.each do |td|
        puts "  столбец=#{td_i}"
        if td.text && !td.text.strip.empty?
          break if td.text.include?('↑')
          puts "    #{td.text.delete('↑').strip}"
          case td_i
          when 0
            data['date'] = td.text.delete('↑').strip
          when 1
            data['city'] = td.text.delete('↑').strip
          when 2
            data['event_name'] = td.text.delete('↑').strip
          end
        end
        td_i += 1
      end
      next if data.empty?
      if tr.css('a[href]')
        url = []
        tr.css('a').each do |link|
          puts "    ссылка=#{link_i}"
          puts "      #{link['href'].strip}"
          url.to_a.append(link['href'].strip)
          link_i += 1
          # parse_files(link['href'].strip)
        end
        data['links'] = url
      end
    end
    result.to_a.append(data) if !data.empty?
    #break if tr_i == 8
  end
  total = result.map {|o| Hash[o.each_pair.to_a]}.to_json
  puts 'done'
  return total
end

# parse_calendar('http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_2018.htm')


def get_links_calendar_by_year(url)
  page = Nokogiri::HTML(open(url.to_s))
  forum = page.css("font[color='#800000']")
  forum.css("a[href]").each do |link|
    if link['href'].include?('tournaments/RU/List_IRGT_RU')
      puts link['href']
      puts link['href'].split('/')[-1]
      result = parse_calendar(link['href'])
      File.write("#{link['href'].split('/')[-1]}.json", result)
      result.clear
    end
  end
end

get_links_calendar_by_year('http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_2018.htm')