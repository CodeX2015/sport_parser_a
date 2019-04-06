# Instead of loading all of Rails, load the
# particular Rails dependencies we need
# https://blog.teamtreehouse.com/active-record-without-rails-app

require 'active_record'

config = YAML.load_file('./config/database.yml')
mode = 'sportcubes_dev'

ActiveRecord::Base.establish_connection config[mode]

# dropdb
# ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(config[mode]).drop
# exit(-1)
begin
  ActiveRecord::Base.connection
rescue ActiveRecord::NoDatabaseError => ex
  p ex.message
  # ActiveRecord::Schema.create_database 'nastart', encoding: 'UTF8', owner: 'echamps'
  database = ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(config[mode].merge(owner: 'postgres'))
  database.create
rescue ActiveRecord::StatementInvalid => ex
  p ex.message
  exit(-1)
end

# Set up database tables and columns
ActiveRecord::Schema.define do

  if !table_exists?(:users)
    create_table :users, force: true do |t|
      t.bigint :person_id, unique: true
      t.text :person_url
      t.text :name, unique: true
      t.text :city
      t.text :age
      t.text :achievement
      t.text :photo
      t.text :school
      t.text :coach
      t.timestamps
    end
  end
  if !table_exists?(:competitions)
    create_table :competitions, force: true do |t|
      t.bigint :comp_id
      t.text :comp_url
      t.text :title
      t.text :discipline
      t.text :result
      t.text :result_place
      t.text :country
      t.text :city
      t.text :length
      t.text :date
      t.text :city_info
      t.integer :fina_scores
      t.text :info_src_url
      t.text :protocol_url
      t.text :polozhenie_url
      t.references :user
      t.timestamps
    end
  end
end

# Set up model classes
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class User < ApplicationRecord
  has_many :competitions
  validates :name, presence: true
  validates :person_id, presence: true
end
class Competition < ApplicationRecord
  belongs_to :user
  validates :title, presence: true
end