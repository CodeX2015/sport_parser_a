require 'open-uri'
require 'nokogiri'

  source = 'http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_2018.htm'

  # получаем содержимое веб-страницы в объект
  page = Nokogiri::HTML(open(source.to_s))


  # производим поиск по элементам с помощью css-выборки
  table = page.css("table[style='border-collapse: collapse;']")

#puts table
i = 0

  table.css('tr').each do |tr|
    puts "tr=#{i}"
    j=0
    k=0
    i+=1
    tr.css('td').each do |td|
      puts "td=#{j}"

      j+=1
      puts td.text
               #.css('.myTblTD1')
      #puts 'next'
    end
    tr
    if tr.css('a[href]') != nil then
      tr.css('a').each do |link|
        puts "link=#{k}"
        k+=1
        #puts link
        #puts link["title"][0].text
        puts link['href']
      end
    end
    # data = Hash.new
    #
    # data['date'] = link.css(".myTblTD1")
    #
    # data['href'] = link['href']
  if i==11 then break end

end
