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

for i in 2011..2015
  puts "Value of local variable is #{i}"
end


# puts Date.strptime('23-25.12.2011', "%d-%d.%m.%Y").strftime("%d.%m.%Y")