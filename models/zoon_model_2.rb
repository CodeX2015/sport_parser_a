# Instead of loading all of Rails, load the
# particular Rails dependencies we need
# https://blog.teamtreehouse.com/active-record-without-rails-app

require 'active_record'


class ZoonDb < ActiveRecord::Base
  config = YAML.load_file('./config/database.yml')
  db = 'zoon_dev'

  establish_connection config[db]
  self.abstract_class = true
  begin
    connection
  rescue ActiveRecord::NoDatabaseError => ex
    p ex.full_message
    # ActiveRecord::Schema.create_database 'nastart', encoding: 'UTF8', owner: 'echamps'
    database = ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(config[db])
    database.create
  rescue ActiveRecord::StatementInvalid => ex
    puts ex.full_message
    connection.execute("DEALLOCATE ALL")
    exit(-1)
  end

end
# Set up model classes
class Gym < ZoonDb
  has_many :coaches
  validates :title, presence: true
end

class Coach < ZoonDb
  belongs_to :gym
  validates :name, presence: true
end
