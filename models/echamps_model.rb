# Instead of loading all of Rails, load the
# particular Rails dependencies we need
# https://blog.teamtreehouse.com/active-record-without-rails-app

require 'active_record'

class EchampsBase < ActiveRecord::Base
  self.abstract_class = true
ActiveRecord::Base.logger = Logger.new(STDOUT)

  def self.close_connection
    connection.disconnect!() if !connection.nil?
  end

  def self.reset_statement
    connection.execute("DEALLOCATE ALL") if !connection.nil?
  end

  def self.reconnect
    if !connection
      establish_connection config[mode]
    end
    while !connection.active?
      begin
        # connection.execute("DEALLOCATE ALL")
        connection.reconnect!()
      rescue => ex
        puts ex.message
        sleep(5)
      end
    end
  end

  config = YAML.load_file('./config/database.yml')
  mode = 'echamps_final'

  establish_connection config[mode]

# dropdb
# ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(config[mode]).drop
# exit(-1)
  begin
    connection
  rescue ActiveRecord::NoDatabaseError => ex
    p ex.message
    # ActiveRecord::Schema.create_database 'nastart', encoding: 'UTF8', owner: 'echamps'
    database = ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(config[mode])
    database.create
  rescue ActiveRecord::StatementInvalid => ex
    p ex.full_message
    puts 'ActiveRecord::StatementInvalid'
    close_connection
    exit(-1)
  rescue PG::ConnectionBad => ex
    puts ex.full_message
    puts 'need check OpenVPN connection'
    reconnect
      # exit(-1)
  rescue PG::InvalidSqlStatementName => ex
    puts ex.full_message
    puts 'need close connection to DB or restart pgbouncer'
    close_connection
    exit(-1)
  rescue => ex
    puts ex.full_message
    puts 'unknown error'
  end

  def self.get_country_id(country)
    country_translation_db = CountryTranslation.find_by("lower(alternate_name) LIKE ?", "#{country.downcase}")
    # country_db = Country.find_by(id: country_translation_db.translatable_id)
    country_id = country_translation_db.translatable_id
    return country_id
  end

  def self.get_region_id(region)
    region_translation_db = RegionTranslation.find_by("lower(alternate_name) LIKE ?", "#{region.downcase}")
    # region_db = Region.find_by(id: region_translation_db.translatable_id)
    region_id = region_translation_db.translatable_id
    return region_id
  end

  def self.get_city_id(city)
    select = '*'
    from = 'city'
    join = 'city_translation'
    order_by = 'population'
    limit = 1
    city_db = City.find_by_sql("SELECT #{select} FROM #{from} INNER JOIN #{join} ON #{join}.translatable_id = #{from}.id WHERE alternate_name LIKE \'#{city}\' ORDER BY #{order_by} DESC LIMIT #{limit}")
    city = Hash.new
    begin
      city[:city_id] = city_db.first.id
      city[:country_id] = city_db.first.country_id
      city[:country_region_id] = city_db.first.country_region_id
    rescue => ex
      puts ex.full_message
      return nil
    end
    return city
  end

# INNER JOIN posts ON posts.author_id = authors.id
# .select('*')
# .joins("INNER JOIN city_translation ON city_translation.translatable_id = city.id")
# .to_sql

# .order(population: :desc)
# .limit(1)
# .select('city.id, city.country_id, city.country_region_id, city.name, city.population, city_translation.translatable_id, city_translation.alternate_name')
# .joins("INNER JOIN city_translation ON city_translation.translatable_id = city.id")
# .where(alternate_name: city)
# city_translation_db = CityTranslation.where("lower(alternate_name) LIKE ?", "#{city.downcase}")
# return nil if !city_translation_db.any?
# city_db = City.where(id: city_translation_db.first.translatable_id).order(population: :desc).first
# city_id = city_db.id
# return city_id
  def self.get_sport_kind_id(sport_kind_name)
    sport_kind_translation_db = SportKindTranslation.find_by("lower(alternate_name) LIKE ?",
                                                             "#{sport_kind_name.downcase[0..-2]}%")
    sport_kind_id = sport_kind_translation_db.nil? ? nil : sport_kind_translation_db.translatable_id
    return sport_kind_id
  end

  def self.get_org_type_id(org_type)
    org_type_db = OrganizationTypeTranslation.find_by("lower(alternate_name) LIKE ?", "#{org_type.downcase}")
    org_type_id = org_type_db.nil? ? nil : org_type_db.translatable_id
    return org_type_id
  end

  def self.next_sequence(object)
    data = object.find_by_sql "SELECT nextval(\'#{object.sequence_name}\') AS next_id"
    data[0].next_id
  end

  def self.alter_sequence_id(object, reset_id)
    object.find_by_sql "ALTER SEQUENCE #{object.sequence_name} RESTART WITH #{reset_id}"
  end

end

# Set up model classes
class User < EchampsBase
  has_one :userprofile
  self.table_name = "user"
  self.sequence_name = "user_id_seq"

  def self.next_id_sequence
    EchampsBase.next_sequence(self)
  end

  def self.alter_sequence_id(reset_id)
    EchampsBase.alter_sequence_id(self, reset_id)
  end
end

class UserProfile < EchampsBase
  self.table_name = "user_profile"
  self.sequence_name = "user_profile_id_seq"
  # has_many :organizations
  # has_many :roles
  # validates :name, presence: true
  def self.next_id_sequence
    EchampsBase.next_sequence(self)
  end

  def self.alter_sequence_id(reset_id)
    EchampsBase.alter_sequence_id(self, reset_id)
  end
end

class UserOrganization < EchampsBase
  self.table_name = "user_organization"
  self.sequence_name = "user_organization_id_seq"

  def self.next_id_sequence
    EchampsBase.next_sequence(self)
  end

  def self.alter_sequence_id(reset_id)
    EchampsBase.alter_sequence_id(self, reset_id)
  end
end

class UserProfileRole < EchampsBase
  self.table_name = "user_profile_role"
  self.sequence_name = "user_profile_role_id_seq"
  self.inheritance_column = :_type_disabled
  # attr_accessor :type
  # has_many :organizations
  # has_many :roles
  # validates :name, presence: true
  def self.next_id_sequence
    EchampsBase.next_sequence(self)
  end

  def self.alter_sequence_id(reset_id)
    EchampsBase.alter_sequence_id(self, reset_id)
  end
end

class UserAchievement < EchampsBase
  self.table_name = "user_achievement"
  self.sequence_name = "user_achievement_id_seq"
  # has_many :organizations
  # has_many :roles
  # validates :name, presence: true
  def self.next_id_sequence
    EchampsBase.next_sequence(self)
  end

  def self.alter_sequence_id(reset_id)
    EchampsBase.alter_sequence_id(self, reset_id)
  end
end

class SportKindTranslation < EchampsBase
  self.table_name = "sport_kind_translation"
  has_one :sportkind
end

class SportKind < EchampsBase
  self.table_name = "sport_kind"
  has_many :userprofiles
end

class CountryTranslation < EchampsBase
  self.table_name = "country_translation"
  has_one :country
end

class Country < EchampsBase
  self.table_name = "country"
  has_many :organizations
  has_many :regions
end

class RegionTranslation < EchampsBase
  self.table_name = "country_region_translation"
  has_one :region
end

class Region < EchampsBase
  self.table_name = "country_region"
  has_one :country
  has_many :organizations
  has_many :cities
end

class CityTranslation < EchampsBase
  self.table_name = "city_translation"
  has_one :region
  has_one :city
  alias_attribute :city_id, :translatable_id
end

class City < EchampsBase
  self.table_name = "city"
  has_many :organizations
  has_many :city_translations
end

class OrganizationType < EchampsBase
  self.table_name = "organization_type"
  has_many :organizations
end

class OrganizationTypeTranslation < EchampsBase
  self.table_name = "organization_type_translation"
  has_many :organizations
end

class Organization < EchampsBase
  has_one :coutry
  has_one :region
  has_one :city
  has_one :organization_type
  validates :name, presence: true
  self.table_name = "organization"
  self.sequence_name = "organization_id_seq"

  def self.next_id_sequence
    EchampsBase.next_sequence(self)
  end

  def self.alter_sequence_id(reset_id)
    EchampsBase.alter_sequence_id(self, reset_id)
  end
end
