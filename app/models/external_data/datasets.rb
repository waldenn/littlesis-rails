# frozen_string_literal: true

class ExternalData
  module Datasets
    mattr_reader :names do
      ExternalData::DATASETS.keys.without(:reserved).map(&:to_s).freeze
    end

    mattr_reader :relationships do
      %w[iapd_schedule_a nys_disclosure].freeze
    end

    mattr_reader :entities do
      (names - relationships).freeze
    end

    mattr_reader :descriptions do
      {
        iapd_advisors: 'Investor Advisor corporations registered with the SEC',
        iapd_schedule_a: 'Owners and board members of investor advisors',
        nycc: 'New York City Council Members',
        nys_disclosure: 'New Yorak State Campaign Contributions',
        nys_filer: 'New York State Campaign Finance Committees'
      }.with_indifferent_access.freeze
    end
  end
end
