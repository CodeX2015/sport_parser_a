# Instead of loading all of Rails, load the
# particular Rails dependencies we need
# https://blog.teamtreehouse.com/active-record-without-rails-app

require 'active_record'

config = YAML.load_file('./config/database.yml')
mode = 'nastart_dev'

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
      t.text :city
      t.text :growth
      t.text :weight
      t.text :discipline
      t.text :achievement
      t.text :about
      t.text :source_url
      t.timestamps
    end
  else
    change_table :users do |t|
      # t.text :nickname
      # t.text :city
      # t.text :growth
      # t.text :weight
      # t.text :discipline
      # t.text :achievement
      # t.text :about
      # t.text :source_url
    end
  end
  if !table_exists?(:competitions)
    create_table :competitions, force: true do |t|
      t.bigint :comp_id
      t.text :title
      t.text :discipline
      t.text :result
      t.text :result_place
      t.text :source_url
      t.text :city
      t.text :date
      t.references :user
      t.timestamps
    end
  else
    # rename_column :competitions, :name, :title
    # , 'integer USING CAST(comp_id AS integer)'
    # change_column :competitions, :comp_id, :integer, using: 'comp_id::integer'
    # add_column :competitions, :source_url, :text
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
  validates :title, presence: true
end