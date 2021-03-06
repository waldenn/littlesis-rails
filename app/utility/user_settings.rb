# frozen_string_literal: true

# Like a struct, but will silently remove any settings not currently defined
class UserSettings
  DEFAULTS = {
    oligrapher_beta: false,
    default_tag: :oligrapher
  }.freeze

  CONVERTERS = Hash.new(->(x) { x }).tap do |hash|
    hash[:oligrapher_beta] = ->(x) { ActiveModel::Type::Boolean.new.cast(x) }
  end.with_indifferent_access.freeze

  SettingsStruct = Struct.new(*DEFAULTS.keys, keyword_init: true)

  attr_reader :settings
  delegate_missing_to :@settings

  def initialize(**kwargs)
    @settings = if kwargs.empty?
                  SettingsStruct.new(DEFAULTS)
                else
                  SettingsStruct.new(DEFAULTS.dup.merge!(kwargs.slice(*DEFAULTS.keys)))
                end
  end

  def update(hash)
    hash.each_pair do |k, v|
      send "#{k}=", CONVERTERS[k].call(v)
    end
  end

  def self.dump(obj)
    raise ActiveRecord::SerializationTypeMismatch unless obj.nil? || obj.is_a?(UserSettings)

    obj.settings.to_json
  end

  def self.load(obj)
    return new if obj.blank?

    raise ActiveRecord::SerializationTypeMismatch unless obj.is_a?(String)

    new(**JSON.parse(obj).symbolize_keys)
  end
end
