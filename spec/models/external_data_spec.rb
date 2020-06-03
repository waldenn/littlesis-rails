describe ExternalData, type: :model do
  it { is_expected.to have_db_column(:dataset).of_type(:integer) }
  it { is_expected.to have_db_column(:dataset_id).of_type(:string) }
  it { is_expected.to have_db_column(:data).of_type(:text) }

  specify 'dataset?' do
    expect(ExternalData.dataset?('nycc')).to be true
    expect(ExternalData.dataset?('NYCC')).to be true
    expect(ExternalData.dataset?('music videos')).to be false
  end

  describe 'datatables_query' do
    let(:nycc_members) do
      [create(:external_data_nycc_borelli), create(:external_data_nycc_constantinides)]
    end

    let(:params) do
      {
        dataset: 'nycc',
        draw: '123',
        search: { value: '', regex: 'false' },
        start: 0,
        length: 10,
        columns: {
          '0' => { data: 'id', name: '' },
          '1' => { data: 'match', name: '' },
          '2' => { data: 'data.FullName', name: '' }
        }
      }
    end

    let(:datatables_params) do
      Datatables::Params.new(ActionController::Parameters.new(params))
    end

    before do
      create(:external_data_iapd_advisor)
      nycc_members
    end

    context 'when requesting entire dataset' do
      it 'returns datatables response' do
        response = ExternalData.datatables_query(datatables_params)
        expect(response).to be_a Datatables::Response
        expect(response.draw).to eq 123
        expect(response.recordsTotal).to eq 2
        expect(response.recordsFiltered).to eq 2
        expect(response.data).to be_a Array
        expect(response.data[0]).to be_a Hash
        expect(response.data.map { |x| x[:id] }.to_set).to eq nycc_members.map(&:id).to_set
      end
    end

    context 'when searching' do
      let(:params) do
        {
          dataset: 'nycc',
          draw: '123',
          search: { value: 'constantinides', regex: 'false' },
          start: 0,
          length: 10,
          columns: {
            '0' => { data: 'id', name: '' },
            '1' => { data: 'match', name: '' },
            '2' => { data: 'data.FullName', name: ''}
          }
        }
      end

      it 'returns filtered result' do
        response = ExternalData.datatables_query(datatables_params)
        expect(response.recordsTotal).to eq 2
        expect(response.recordsFiltered).to eq 1
        expect(response.data.first[:data]['FullName']).to match /constantinides/i
      end
    end
  end
end
