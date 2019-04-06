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
      t.bigint :source_user_id
      t.text :nickname
      t.text :photo
      t.timestamps
    end
  else
    # add_column :users, :comp_url, :text
  end
  if !table_exists?(:competitions)
    create_table :competitions, force: true do |t|
      t.bigint :comp_id
      t.text :name
      t.text :discipline
      t.text :source_url
      t.text :city
      t.text :date
      t.references :user
      t.timestamps
    end
  else
    if !column_exists?(:competitions, :comp_url, :text)
      # puts 'not exists'
      # add_column :competitions, :comp_url, :text
      change_table :competitions do |t|
        t.text :comp_url
      end
    else
      # puts 'exists'
    end
    # change_column :competitions, :comp_id, 'integer USING CAST(comp_id AS integer)'
    # change_column :competitions, :comp_id, :integer, using: 'comp_id::integer'
  end
  if !table_exists?(:results)
    create_table :results, force: true do |t|
      t.text :discipline
      t.text :result
      t.text :place
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
end
class Competition < ApplicationRecord
  belongs_to :user
  validates :name, presence: true

  def self.check_columns
    ActiveRecord::Schema.define do
      # rename_column :competitions, :comp_url, :comp_url_new
      add_column :competitions, :comp_url, :text if !column_exists?(:competitions, :comp_url, :text)
      # add_column :competitions, :about, :text if !column_exists?(:competitions, :about, :text)
      change_column :competitions, :about, :string if !column_exists?(:competitions, :about, :text)

    end
  end
end

class Discipline < ApplicationRecord
  belongs_to :competition
  validates :name, presence: true
end

class Result < ApplicationRecord
  has_many :disciplines
  validates :name, presence: true
end