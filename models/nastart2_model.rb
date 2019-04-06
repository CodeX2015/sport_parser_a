# Instead of loading all of Rails, load the
# particular Rails dependencies we need
# https://blog.teamtreehouse.com/active-record-without-rails-app

require 'active_record'

config = YAML.load_file('./config/database.yml')
mode = 'test_dev'

ActiveRecord::Base.establish_connection config[mode]

# dropdb
# ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(config[mode]).drop
# exit(-1)
begin
  ActiveRecord::Base.connection
rescue ActiveRecord::NoDatabaseError => ex
  p ex.message
  # ActiveRecord::Schema.create_database 'nastart', encoding: 'UTF8', owner: 'echamps'
  database = ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(config[mode])
  database.create
rescue ActiveRecord::StatementInvalid => ex
  p ex.message
  exit(-1)
end

# Set up database tables and columns
ActiveRecord::Schema.define do

  if !table_exists?(:users)
    create_table :users, force: true do |t|
      t.text :name, unique: true
      t.text :birthday
      t.text :city_team
      t.text :photo
      t.text :nickname
      t.bigint :growth
      t.bigint :weight
      t.text :discipline
      t.text :achievement
      t.text :about
      t.bigint :source_user_id
      t.text :source_user_url

      t.timestamps
    end
  end

  if !table_exists?(:competitions)
    create_table :competitions, force: true do |t|
      t.text :title
      t.text :city
      t.bigint :source_comp_id
      t.text :source_comp_url

      t.timestamps
    end
  end

  if !table_exists?(:results)
    create_table :results, force: true do |t|
      t.date :date
      t.text :time
      t.text :place

      t.references :discipline
      t.references :user
      t.references :competition

      t.timestamps
    end
  end

  if !table_exists?(:disciplines)
    create_table :disciplines, force: true do |t|
      t.text :title, unique: true

      t.timestamps
    end
  end
end

# Set up model classes
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class User < ApplicationRecord
  has_many :results
  has_many :competitions, through: :results
  has_many :desciplines, through: :results

  validates :name, uniqueness: true
end

class Competition < ApplicationRecord
  has_many :results
  has_many :users, through: :results
  has_many :desciplines, through: :results

  validates :title, presence: true, uniqueness: true
end

class Discipline < ApplicationRecord
  has_many :results
  has_many :users, through: :results
  has_many :competitions, through: :results

  validates :title, presence: true, uniqueness: true
end

class Result < ApplicationRecord
  belongs_to :discipline
  belongs_to :competition
  belongs_to :user
end

