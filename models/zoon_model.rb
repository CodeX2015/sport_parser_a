# Instead of loading all of Rails, load the
# particular Rails dependencies we need
# https://blog.teamtreehouse.com/active-record-without-rails-app

require 'active_record'


config = YAML.load_file('./config/database.yml')
db = 'zoon_dev'

ActiveRecord::Base.establish_connection config[db]

begin
  ActiveRecord::Base.connection
rescue ActiveRecord::NoDatabaseError => ex
  p ex.message
  # ActiveRecord::Schema.create_database 'nastart', encoding: 'UTF8', owner: 'echamps'
  database = ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(config[db])
  database.create
rescue ActiveRecord::StatementInvalid => ex
  puts ex.message
  exit(-1)
end

# Set up database tables and columns
ActiveRecord::Schema.define do
  # create_database 'zoon', encoding: 'UTF8', owner: 'echamps'
  if !table_exists?(:gyms)
    create_table :gyms, force: true do |t|
      t.text :title, unique: true
      t.text :rating
      t.text :comment
      t.text :address

      t.timestamps
    end
  end
  if !table_exists?(:coaches)
    create_table :coaches, force: true do |t|
      t.text :photo
      t.text :name
      t.text :phone
      t.text :rating
      t.text :comment
      t.text :info
      t.text :specialty
      t.text :specialization
      t.text :education
      t.text :experience
      t.text :area
      t.text :address
      t.text :price
      t.text :docs
      t.text :source_id
      t.text :source_url
      t.references :gym

      t.timestamps
    end
  end
end

# Set up model classes
class DevDatabase < ActiveRecord::Base
  self.abstract_class = true
end

class Gym < DevDatabase
  has_many :coaches
  validates :title, presence: true
end

class Coach < DevDatabase
  belongs_to :gym
  validates :name, presence: true
end
