# rubocop:disable Rails/Date, RSpec/MessageSpies

describe NYSDisclosureImporter do
  let(:testdata) do
    Rails.root.join('spec/testdata/nys_campaign_finance_all_reports.zip').to_s
  end

  before do
    stub_const('NYSDisclosureImporter::LOCAL_PATH', testdata)
  end

  describe 'when downloading should happen' do
    specify 'file does not exist' do
      expect(Utility).to receive(:file_is_empty_or_nonexistent).once.and_return(true)
      expect(Utility).to receive(:stream_file).once
      NYSDisclosureImporter.run
    end

    specify 'file exists and was edited yesterday' do
      expect(Utility).to receive(:file_is_empty_or_nonexistent).once.and_return(false)
      expect(File).to receive(:ctime).once.and_return(Time.zone.yesterday.to_time)
      expect(Utility).to receive(:stream_file).once
      NYSDisclosureImporter.run
    end

    specify 'file exists and was edited today' do
      expect(Utility).to receive(:file_is_empty_or_nonexistent).once.and_return(false)
      expect(File).to receive(:ctime).once.and_return(Time.zone.today.to_time)
      expect(Utility).not_to receive(:stream_file)
      NYSDisclosureImporter.run
    end
  end

  it 'creates 10 ExternalData' do
    expect { NYSDisclosureImporter.run }.to change(ExternalData, :count).by(10)
  end

  it 'creates 10 ExternalRelationship' do
    expect { NYSDisclosureImporter.run }.to change(ExternalRelationship, :count).by(10)
  end
end

# rubocop:enable Rails/Date, RSpec/MessageSpies
