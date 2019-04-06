class Utils

  class << self
    require 'date'

    def fix_dates
      dates = ['23-25.12.2011', '23.11-28.12.2011', '22.01.201825.01.2018', '21.11.2015']

      dates.each do |d|
        if d.include?('-')
          a_d = d.split('-')
          case a_d[0].to_s.length
          when 2
            puts "#{a_d[0]}#{a_d[1].to_s[2..-1]}-#{a_d[1]}"
          when 5
            puts "#{a_d[0]}#{a_d[1].to_s[5..-1]}-#{a_d[1]}"
          end
        elsif d.to_s.length > 10
          puts "#{d[0..9]}-#{d[10..-1]}"
        else
          puts d
        end
      end

    end

    def extract_numbers_from_string(line)
      return line.scan(/\d/).join('')
    end

    def create_csv_from_hash_with_headers(hash_csv, path)
      require 'csv'
      headers = hash_csv[0].keys
      begin
        CSV.open(path, 'wb', col_sep: ";", encoding: "cp1251",
                 headers: headers, write_headers: true) {
            |csv| hash_csv.to_a.each {|elem| csv << elem.values.map {|s|
            s.encode('cp1251', invalid: :replace, undef: :replace, replace: '')}}
        }
          # |e| e.encode("cp1251")
          # |s| s.encode('ASCII', 'binary', invalid: :replace, undef: :replace, replace: '')
      rescue => ex
        puts "[ERR] #{path} save in UTF-8 need manual encoding \n#{ex.message}"
        CSV.open(path, 'wb', col_sep: ";", headers: headers, write_headers: true) {
            |csv| hash_csv.to_a.each {|elem| csv << elem.values}
        }
      end
    end

    def read_csv_file(filename)
      require 'csv'
      begin
        hashed_data = CSV.read(filename, col_sep: ';',
                               encoding: 'Windows-1251:utf-8', headers: true).map(&:to_h)
          # headers = ["id", 'date', 'discipline', 'results', 'place', 'city', 'comp_url', 'comp_id']
          # data = CSV.read(filename, col_sep: ';', encoding: 'cp1251', headers: headers)
          # data = CSV.read(filename, col_sep: ';', encoding: 'cp1251', headers: true)
          # hashed_data = data.map {|d| d.to_hash}
      rescue => ex
        puts "[ERR] #{filename} read in UTF-8 \n#{ex.message}"
        hashed_data = CSV.open(filename, 'wb', col_sep: ";", headers: true).map(&:to_h)
      end
      return hashed_data
    end

    def convert_hash_to_json(hash)
      require 'json'
      return hash.to_json
    end

    def read_json_file(filename)
      require 'json'
      return JSON.parse(IO.read(filename, encoding: 'utf-8'))
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

    def create_json_from_hash(hash, path_to_save)
      save_to_file(path_to_save, convert_hash_to_json(hash))
    end

    def titleize_fio(str)
      return str.split(' ').map(&:capitalize).join(' ')
    end

    def titleize(str)
      return str.capitalize
    end

    def sanitize_char_except_letters(str)
      return str.gsub(/[^a-zа-я ]/i, '')
    end

    def test
      puts "test OK!"
    end

    def convert_db_object_to_json(object)
      require 'json'
      return object.as_json.to_json
    end

    def remove_whitespaces(str)
      return str.gsub(/[[:space:]]/, ' ').gsub(/\s+/, " ").strip
    end

    def normalize_string(str)
      return str if str.nil?
      return str
                 .gsub(/\:(?![ ])/, ': ')
                 .gsub(/\.(?![ ])/, '. ')
                 .gsub(/\;(?![ ])/, '; ')
                 .gsub(/\,(?![ ])/, ', ')
                 .gsub(/\!(?![ ])/, '! ')
                 .gsub(/\?(?![ ])/, '? ')
                 .gsub(/(?<=[a-z]|[а-я])(?=[A-Z]|[А-Я])/, ' ')
    end

    def convert_csv_to_json(file)
      require 'json'
      require 'csv'

      filename = "#{File.dirname(file)}/#{File.basename(file, '.csv')}.json"
      create_json_from_hash(read_csv_file(file), filename)
    end

    def convert_json_to_csv(file)
      require 'json'
      require 'csv'

      filename = "#{File.dirname(file)}/#{File.basename(file, '.json')}.csv"
      create_csv_from_hash_with_headers(read_json_file(file), filename)
    end

    def gen_md5(str)
      # todo after fix
      require 'digest/md5'
      md5 = Digest::MD5.new
      return md5.hexdigest(str)
      #[0..21]
    end

    def convert_latin_to_arabic(number)
      convert_latin_to_arabic = {
          'X' => 10,
          'IX' => 9,
          'VIII' => 8,
          'VII' => 7,
          'VI' => 6,
          'V' => 5,
          'IV' => 4,
          'III' => 3,
          'II' => 2,
          'I' => 1
      }
      return convert_latin_to_arabic(number)
    end

    def convert_rank(rank)
      rank_associate = {
          "I"=> 'I разряд',
          "II"=> 'II разряд',
          "III"=> 'III разряд',
          "КМС"=> 'Кандидат в Мастера Спорта',
          "МС"=> 'Мастер Спорта',
          "ЗМС"=> 'Заслуженный Мастер Спорта'
      }
      result = rank_associate[rank]
      return result
    end


    def symbolize_keys(obj)
      case obj
      when Array
        obj.inject([]) {|res, val|
          res << case val
                 when Hash, Array
                   symbolize_keys(val)
                 else
                   val
                 end
          res
        }
      when Hash
        obj.inject({}) {|res, (key, val)|
          nkey = case key
                 when String
                   key.to_sym
                 else
                   key
                 end
          nval = case val
                 when Hash, Array
                   symbolize_keys(val)
                 else
                   val
                 end
          res[nkey] = nval
          res
        }
      else
        obj
      end
    end

# for i in 2011..2015
#   puts "Value of local variable is #{i}"
# end
# require 'nokogiri'
# str = '<td>25-27.12.2011</td><td class="myTblTD1" align="center"><a target="_blank" href="http://rg4u.clan.su/forum/32-187-13783-16-1323410954"></a></td>'
# page = Nokogiri::HTML(str)
# page.css('td').each do |td|
#   if td.css('a[href]').count==0
#     puts td.text
#   end

# end
# puts Date.strptime('23-25.12.2011', "%d-%d.%m.%Y").strftime("%d.%m.%Y")

  end

  def self.hash_replace_value(hash, from, to)
    return Hash[hash.map {|k, v| [k, v == from ? to : v]}]
  end
end