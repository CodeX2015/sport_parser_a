require 'open-uri'
require 'nokogiri'

$download_path = "E:\\Ruby\\WorkSpace\\sport_parser_a\\downloads\\"

def get_path_by_url(url)
  path = url.split('/').last
  return "#{$download_path}#{path}\\"
end

def download_file(url, path)
  begin
    download = open(url)
    puts "#{path}#{download.base_uri.to_s.split('/')[-1]}"
    file_path = path + download.base_uri.to_s.split('/')[-1]
    File.exist?(file_path) ? puts('file already exist') : IO.copy_stream(download, file_path)
      # IO.copy_stream(download, file_path) if !File.exist?(file_path)
  rescue => ex
    puts ex.message
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

      download_file(img['src'], download_path) if !img['src'].include?('s106.ucoz.net') &&
          !img['src'].include?("rg4u.clan.su/imgr/") &&
          !img['src'].include?("rg4u.clan.su") &&
          img['src'].include?("http")

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

  # parse_forum('http://rg4u.clan.su/forum/32-3315-1')
  # parse_news('http://rg4u.clan.su/news/sorevnovanija_po_khudozhestvennoj_gimnastike_parad_gracij_26_28_01_2018_saransk_respublika_mordovija/2018-01-04-2779')
end

parse_files('http://rg4u.clan.su/forum/32-3315-1')