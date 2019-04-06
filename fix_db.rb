# coding: utf-8

# XXX/ This code is requirements only for cyrillic symbols on windows
if (Gem.win_platform?)
  Encoding.default_external = Encoding.find(Encoding.locale_charmap)
  Encoding.default_internal = __ENCODING__
  # io.set_encoding(Encoding.default_external, Encoding.default_internal)
  [STDIN, STDOUT].each {|io| io.set_encoding(Encoding.default_internal)}
end
# /XXX

require 'sqlite3'
# require 'optparse'

SQLITE_DB_FILE = 'development.sqlite3'.freeze

#
# options = {}
#
# OptionParser.new do |opt|
#   opt.banner = 'Usage fix_db.rb [options]'
#   opt.on('-h', 'Prints this help') do
#     puts opt
#     exit
#   end
#   opt.on('--date_from TOURNAMENTS_DATE_FROM', 'Which date of event show(default all)') {|o| options[:date_from] = o}
#   opt.on('--city TOURNAMENTS_CITY', 'Which type of post show(default all)') {|o| options[:city] = o}
# end.parse!

def update_in_db(tournament)
  db = SQLite3::Database.open(SQLITE_DB_FILE)
  db.results_as_hash = true
  query = "UPDATE tournaments SET date_from = ?, date_to = ? WHERE id = ?"
  db.execute(query, tournament['date_from'].to_s, tournament['date_to'].to_s, tournament['id'])
  # statement = db.prepare(query)
  # statement.bind_params('date_from', tournament['date_from'])
  # statement.bind_params('date_to', tournament['date_to'].to_s) unless tournament['date_to'].nil?
  # statement.bind_params('id', tournament['id']) unless tournament['id'].nil?
  # statement.execute!
  # statement.close
  db.close
end

def read_from_db(id)
  db = SQLite3::Database.open(SQLITE_DB_FILE)
  db.results_as_hash = true
  tournaments = db.execute("SELECT * FROM tournaments")

  # " WHERE id=?", id)
  db.close
  tournaments.each do |tournament|
    begin
      tournament['date_from'] = Date.strptime(tournament['date_from'].delete(' ').strip, "%d.%m.%Y") if !tournament['date_from'].include?('-')
      tournament['date_to'] = Date.strptime(tournament['date_to'].delete(' ').strip, "%d.%m.%Y") if !tournament['date_to'].include?('-')
      # print "id: #{tournament['id']} from: #{tournament['date_from']} _ "
      # print tournament['date_from'] = Date.strptime(tournament['date_from'].delete(' ').strip, "%d.%m.%Y")
      # print " end: #{tournament['date_to']} _ "
      # print  tournament['date_to'] = Date.strptime(tournament['date_to'].delete(' ').strip, "%d.%m.%Y") if !tournament['date_to'].include?('-')
      # puts
      update_in_db(tournament)
    rescue => ex
      puts ex.full_message
    end
  end
end

read_from_db(1)


def save_to_db(tournament)
  db = SQLite3::Database.open(SQLITE_DB_FILE)
  db.results_as_hash = true

  # tournaments_hash = to_db_hash

  db.execute(
      "INSERT INTO tournaments (" +
          tournaments_hash.keys.join(', ') +
          ") VALUES (#{('?,' * tournaments_hash.size).chomp(',')})",
      tournaments_hash.values
  )

  # insert_row_id = db.last_insert_row_id
  # db.close
  # insert_row_id
end

def to_db_hash
  {
      'type' => self.class.name,
      'created_at' => @created_at.to_s
  }
end