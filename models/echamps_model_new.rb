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
        connection.reconnect!()
      rescue => ex
        puts ex.message
        sleep(2)
      end
    end
  end

  config = YAML.load_file('./config/database.yml')
  mode = 'echamps_dev'

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
    select = 'city.id AS city_id, *'
    from = 'city'
    join = 'city_translation'
    order_by = 'population'
    limit = 1
    city_db = City.find_by_sql("SELECT #{select} FROM #{from} INNER JOIN #{join} ON #{join}.translatable_id = #{from}.id WHERE alternate_name LIKE \'#{city}\' ORDER BY #{order_by} DESC LIMIT #{limit}")
    city = Hash.new
    begin
      city[:city_id] = city_db.first.city_id
      city[:country_id] = city_db.first.country_id
      city[:country_region_id] = city_db.first.country_region_id
    rescue => ex
      puts ex.full_message
      return {city_id: nil, country_id: nil, country_region_id: nil}
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

  def self.get_rank_id(rank_name)
    rank_db = Rank.find_by(name: rank_name)
    rank_id = rank_db.nil? ? nil : rank_db.id
    return rank_id
  end

  def self.get_discipline_kind_id(sport_kind_id, discipline_kind)
    discipline_kind_db = SportKindDiscipline.find_by("sport_kind_id = ? and name LIKE ?",
                                                     sport_kind_id, "#{discipline_kind}")
    discipline_kind_id = discipline_kind_db.nil? ? nil : discipline_kind_db.id
    return discipline_kind_id
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

  def self.db_rollback(object, rollback_type)
    puts rollback_type
    begin
      case rollback_type
      when :event
        Event.alter_sequence_id(object[:id]) if !object[:id].nil?
        Event.destroy(object[:id]) if Organization.exists?(object[:id])
      when :organization
        Organization.alter_sequence_id(object[:id]) if !object[:id].nil?
        Organization.destroy(object[:id]) if Organization.exists?(object[:id])
      when :user
        User.alter_sequence_id(object[:user_id]) if !object[:user_id].nil?
        User.destroy(object[:user_id]) if User.exists?(object[:user_id])
      when :user_profile
        UserProfile.destroy(object[:id]) if UserProfile.exists?(object[:id])
        UserProfile.alter_sequence_id(object[:id]) if !object[:id].nil?
        User.destroy(object[:user_id]) if User.exists?(object[:user_id])
        User.alter_sequence_id(object[:user_id]) if !object[:user_id].nil?
      when :user_organization
        UserOrganization.destroy(object[:user_organization_id]) if UserOrganization
                                                                       .exists?(object[:user_organization_id])
        UserOrganization.alter_sequence_id(object[:user_organization_id]) if !object[:user_organization_id].nil?
      when :user_profile_role
        UserProfileRole.destroy(object[:id]) if UserProfileRole.exists?(object[:id])
        UserProfileRole.alter_sequence_id(object[:id]) if !object[:id].nil?
      when :user_achievement
        UserAchievement.alter_sequence_id(object[:id]) if !object[:achievement_id].nil?
        UserAchievement.destroy(object[:id]) if UserAchievement.exists?(object[:achievement_id])
      else
        puts "ERR unknown rollback type: #{rollback_type}"
      end
    rescue => ex
      puts ex.full_message
    end
    raise "ERR rollback #{rollback_type}".blue
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

  def self.create_user_db(user_profile)
    begin
      user_profile[:user_id] = next_id_sequence
      user_profile[:email] = "#{user_profile[:user_id]}@e-champs.com"
      password = Utils.gen_md5(user_profile[:email])
      transaction do
        user_db = create(
            id: user_profile[:user_id], username: user_profile[:email],
            email: user_profile[:email], roles: user_profile[:roles],
            is_cms_user: user_profile[:is_cms_user], enabled: user_profile[:enabled],
            password: password, status: user_profile[:status],
            user_agreement: user_profile[:user_agreement],
            gdpr_argreement: user_profile[:gdpr_argreement],
            is_created_user: user_profile[:is_created_user]
        )

        return user_db
      end
    rescue => ex
      puts ex.full_message.red
      db_rollback(user_profile, :user)
      # exit(-1)
    end
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

  def self.create_user_profile_db(user_profile)
    # проверяем пользователя в таблице профиля по имя фамилия город
    user_profile_db = find_by('first_name LIKE ? AND last_name LIKE ? AND city_id = ?',
                              user_profile[:first_name],
                              user_profile[:last_name],
                              user_profile[:city_id])

    # если не нашли, то просто по имени и фамилии,
    user_profile_db = find_by('first_name LIKE ? AND last_name LIKE ?',
                              user_profile[:first_name],
                              user_profile[:last_name]
    ) if user_profile_db.nil?
    return user_profile_db if !user_profile_db.nil?

    # если не нашли, то создаем пользователя
    user_db = User.create_user_db(user_profile)
    user_profile[:user_id] = user_db.id
    user_profile[:email] = user_db.email

    begin
      user_profile[:id] = next_id_sequence
      if !user_profile[:image_original_name].nil? and user_profile[:image_original_name].include?('.')
        photo = user_profile[:image_original_name].split('.')
        user_profile[:image_name] = "#{Utils.gen_md5(photo[0])}.#{photo[-1]}"
      else
        user_profile[:image_name] = nil
      end
      transaction do
        user_profile_db = create(
            id: user_profile[:id], country_id: user_profile[:country_id],
            city_id: user_profile[:city_id], user_id: user_profile[:user_id],
            first_name: user_profile[:first_name], last_name: user_profile[:last_name],
            middle_name: user_profile[:middle_name], birthday: user_profile[:birthday],
            gender: user_profile[:gender], email: nil, phone: nil,
            user_type: user_profile[:user_type], image_name: user_profile[:image_name],
            year_of_birth: user_profile[:year_of_birth],
            image_original_name: user_profile[:image_original_name],
            about: user_profile[:about], country_region_id: user_profile[:country_region_id],
            source_link: user_profile[:source_link], internal_notes: user_profile[:phone]
        )
        return user_profile_db
      end
    rescue => ex
      puts ex.full_message.red
      db_rollback(user_profile, :user_profile)
      # exit(-1)
    end
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

  def self.create_user_organization_db(user_profile)
    user_profile[:user_organization_id] = nil
    user_org_db = find_by(user_profile_id: user_profile[:id],
                          organization_id: user_profile[:organization_id],
                          position_id: user_profile[:position_id])
    return user_org_db if !user_org_db.nil?
    begin
      user_profile[:user_organization_id] = next_id_sequence
      user_org_db = create(
          id: user_profile[:user_organization_id],
          user_profile_id: user_profile[:id],
          organization_id: user_profile[:organization_id],
          is_current: true,
          position_id: user_profile[:position_id]
      )
      return user_org_db
    rescue => ex
      puts ex.full_message.red
      db_rollback(user_profile, :user_organization)
      # exit(-1)
    end
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

  def self.create_user_profile_role_db(user_profile, role)
    user_profile_role_db = find_by(
        user_profile_id: user_profile[:id],
        type: user_profile[:user_type],
        sport_kind_id: role[:sport_kind_id],
        rank_id: role[:rank_id],
        coach_specialization_id: role[:coach_specialization_id],
        coach_category_id: role[:coach_category_id]
    )
    return user_profile_role_db if !user_profile_role_db.nil?

    begin
      # создаем роль
      role[:user_profile_id] = user_profile[:id]
      role[:role_id] = next_id_sequence
      user_profile_role_db = create(
          id: role[:role_id], user_profile_id: user_profile[:id],
          sport_kind_id: role[:sport_kind_id], rank_id: role[:rank_id],
          organization_id: user_profile[:organization_id],
          coach_category_id: role[:coach_category_id],
          coach_specialization_id: role[:coach_specialization_id],
          type: user_profile[:user_type],
          is_main: true
      )
      return user_profile_role_db
    rescue => ex
      puts ex.full_message.red
      db_rollback(role, :user_profile_role)
      # exit(-1)
    end
  end
end

class Event < EchampsBase
  self.table_name = "event"
  self.sequence_name = "event_id_seq"

  def self.next_id_sequence
    EchampsBase.next_sequence(self)
  end

  def self.alter_sequence_id(reset_id)
    EchampsBase.alter_sequence_id(self, reset_id)
  end

  def self.create_event_db(event)
    event_db = find_by(
        event_type_id: event[:event_type_id],
        sport_kind_id: event[:sport_kind_id],
        name: event[:name],
        city_id: event[:city_id]
    )
    return event_db if !event_db.nil?
    begin
      event[:id] = next_id_sequence
      event_db = create(
          id: event[:id],
          event_type_id: event[:event_type_id],
          sport_kind_id: event[:sport_kind_id],
          country_region_id: event[:country_region_id],
          country_id: event[:country_id], city_id: event[:city_id],
          sport_facility_id: event[:sport_facility_id], description: event[:description],
          organization_id: event[:org_id], event_category_id: event[:event_category_id],
          name: event[:name], start_date: event[:start_date], end_date: event[:end_date]
      )
      return event_db
    rescue => ex
      puts ex.full_message.red
      db_rollback(event, :event)
    end
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

  def self.create_user_achievement_db(user, event)
    user_achievement_db = find_by(
        sport_kind_id: event[:sport_kind_id],
        sport_kind_discipline_id: event[:sport_kind_discipline_id],
        city_id: event[:city_id],
        event_id: event[:id],
        user_profile_id: user[:id],
        event_date: event[:start_date]
    )
    return user_achievement_db if !user_achievement_db.nil?
    begin
      event[:achievement_id] = next_id_sequence
      user_achievement_db = create(
          id: event[:achievement_id],
          sport_kind_id: event[:sport_kind_id],
          sport_kind_discipline_id: event[:sport_kind_discipline_id],
          country_region_id: event[:country_region_id],
          country_id: event[:country_id], city_id: event[:city_id],
          event_id: event[:id],
          user_profile_id: user[:id],
          event_date: event[:start_date],
          role: user[:user_type], place: event[:place],
          result: event[:result], status: 1, is_hidden: false
      )
      return user_achievement_db
    rescue => ex
      puts ex.full_message.red
      db_rollback(event, :user_achievement)
    end
  end
end

class SportKindDiscipline < EchampsBase
  self.table_name = "sport_kind_discipline"
end

class SportKindTranslation < EchampsBase
  self.table_name = "sport_kind_translation"
  has_one :sportkind
end

class SportKind < EchampsBase
  self.table_name = "sport_kind"
  has_many :userprofiles
end

class Rank < EchampsBase
  self.table_name = "rank"
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

  def self.create_organization_db(org)
    # проверяем организацию в таблице организации
    org_db = find_by('lower(name) LIKE ?', "#{org[:name].downcase}%")
    return org_db if org_db
    begin
      org[:id] = next_id_sequence
      org_db = create(
          id: org[:id], country_id: org[:country_id], country_region_id: org[:country_region_id],
          city_id: org[:city_id], organization_type_id: org[:organization_type_id],
          name: org[:name], street: org[:street], status: org[:status]
      )
      return org_db
    rescue => ex
      puts ex.message.red
      db_rollback(org, :organization)
      # exit(-1)
    end
  end

end

