# Instead of loading all of Rails, load the
# particular Rails dependencies we need
# https://blog.teamtreehouse.com/active-record-without-rails-app

require 'active_record'

require 'logger'
ActiveRecord::Base.logger = Logger.new(STDOUT)

class ZoonDb < ActiveRecord::Base
  config = YAML.load_file('./config/database.yml')
  db = 'zoon_dev'

  establish_connection config[db]

  begin
    connection
  rescue ActiveRecord::NoDatabaseError => ex
    p ex.message
    # ActiveRecord::Schema.create_database 'nastart', encoding: 'UTF8', owner: 'echamps'
    database = ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(config[db])
    database.create
  rescue ActiveRecord::StatementInvalid => ex
    p ex.message
    exit(-1)
  end

  self.abstract_class = true

  def self.next_sequence(object)
    data = object.find_by_sql "SELECT nextval(\'#{object.sequence_name}\') AS next_id"
    data[0].next_id
  end

  def self.get_country_id(country)
    country_translation_db = CountryTranslation.find_by("lower(alternate_name) LIKE ?", "#{country.downcase}")
    # country_db = Country.find_by(id: country_translation_db.translatable_id)
    country_id = country_translation_db.translatable_id
    return country_id
  end


end

# Set up database tables and columns
# ActiveRecord::Schema.define do
#   self.verbose = true # or false
#   @connection = ZoonDb.connection
#
#   if !ActiveRecord::Migration.table_exists?(:gyms)
#     ActiveRecord::Migration.create_table :gyms, force: true do |t|
#       t.text :title, unique: true
#       t.text :rating
#       t.text :comment
#       t.text :address
#
#       t.timestamps
#     end
#   end
# end

class EchampsDb < ActiveRecord::Base

  config = YAML.load_file('./config/database.yml')
  db = 'echamps_dev'

  establish_connection config[db]

  begin
    connection
  rescue ActiveRecord::NoDatabaseError => ex
    p ex.message
    # ActiveRecord::Schema.create_database 'nastart', encoding: 'UTF8', owner: 'echamps'
    database = ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(config[db])
    database.create
  rescue ActiveRecord::StatementInvalid => ex
    p ex.message
    exit(-1)
  end

  self.abstract_class = true

  def self.next_sequence(object)
    data = object.find_by_sql "SELECT nextval(\'#{object.sequence_name}\') AS next_id"
    data[0].next_id
  end

  def self.get_country_id(country)
    country_translation_db = CountryTranslation.find_by("lower(alternate_name) LIKE ?", "#{country.downcase}")
    # country_db = Country.find_by(id: country_translation_db.translatable_id)
    country_id = country_translation_db.translatable_id
    return country_id
  end
end

# Set up model classes
class Gym < ZoonDb
  has_many :coaches
  validates :title, presence: true
end

class CountryTranslation < EchampsDb
  self.table_name = "country_translation"
  has_one :country
end

class Country < EchampsDb
  self.table_name = "country"
  has_many :organizations
  has_many :regions
end
