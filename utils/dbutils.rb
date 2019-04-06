class Dbutils
  require 'pg' # postgresql

  class << self

    # db = SQLite3::Database.new 'myParser.db'

    def get_from_db


      conn = PG.connect("192.168.43.15", 5432, '', '', "zoon", "postgres", "%@#UNKBfpXgU")
      res = conn.exec('select coach_id, coach_name, coach_info from coach')

      res.each do |row|
        puts row
      end
    end

    def save_to_db

    end


  end

end