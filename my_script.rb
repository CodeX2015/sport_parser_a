require 'open-uri'
require 'nokogiri'

  source = 'http://rg4u.clan.su/tournaments/RU/List_IRGT_RU_2018.htm'

  # получаем содержимое веб-страницы в объект
  page = Nokogiri::HTML(open(source.to_s))


  # производим поиск по элементам с помощью css-выборки
  table = page.css("table[style='border-collapse: collapse;']")

#puts table

  table.css('tr').each do |tr|
    tr.css('td').each do |td|
      #puts td
      puts td.text
               #.css('.myTblTD1')
      #puts 'next'
    end
    # data = Hash.new
    #
    # data['date'] = link.css(".myTblTD1")
    #
    # data['href'] = link['href']
  #break

end
