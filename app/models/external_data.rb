# frozen_string_literal: true

class ExternalData < ApplicationRecord
  DATASETS = { reserved: 0,
               iapd_advisors: 1,
               iapd_owners: 2 }.freeze

  enum dataset: DATASETS

  serialize :data

  # has_one :external_entity

  def setup_data_column
    return self if data.present?

    case dataset
    when 'iapd_advisors', 'iapd_owners'
      self.data = []
    end

    self
  end
end
