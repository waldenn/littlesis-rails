# frozen_string_literal: true

module ExternalDataSphinxQuery
  def self.run(params)
    query = params.search_requested? ? params.search_value : nil

    options = {
      indices: ["external_data_#{params.dataset}_core"],
      order: params.order_sql,
      page: (params.start / params.length) + 1,
      per_page: params.length,
      sql: active_record_sql(params.dataset),
      with: sphinx_filter(params)
    }

    sphinx_search = ExternalData.search(query, options)

    Datatables::Response.new(draw: params.draw).tap do |response|
      response.recordsTotal = ExternalData.public_send(params.dataset).count
      response.recordsFiltered = sphinx_search.count
      response.data = make_datatables_array(sphinx_search)
    end
  end

  # helper methods
  # sql => :include, :joins, :select, :order
  def self.active_record_sql(dataset)
    case dataset
    when 'nys_disclosure'
      ExternalData::Datasets::NYSDisclosure::SCOPE
    else
      {}
    end
  end

  def self.sphinx_filter(params)
    {}.tap do |h|
      h.merge! params.nys_disclosure_filter if params.dataset == 'nys_disclosure'
      h.store(:matched, true) if params.matched == :matched
      h.store(:matched, false) if params.matched == :unmatched
    end
  end

  def self.make_datatables_array(sphinx_search)
    sphinx_search.to_a.map(&:datatables_json)
  end

  def self.nys_disclosure_search(query = nil, start: 0, length: 10, transaction_codes: 'contributions', matched: :unmatched)
    run Datatables::Params.from_hash(
      draw: 1,
      search: { value: query },
      dataset: 'nys_disclosure',
      start: start,
      length: length,
      columns: [{ data: 'id' }, { data: 'amount' }, { data: 'date' }],
      order: [{ column: 0, dir: 'desc' }],
      transaction_codes: Array.wrap(transaction_codes),
      matched: matched
    )
  end

  private_class_method :active_record_sql, :make_datatables_array, :sphinx_filter
end
