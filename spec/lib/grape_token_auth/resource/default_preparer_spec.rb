# frozen_string_literal: true

module GrapeTokenAuth::Resource
  RSpec.describe DefaultPreparer do
    it_behaves_like 'a resource preparer'
    let(:resource) { double('resource') }

    describe '.prepare' do
      it 'returns a hash with the passed resource under the data key' do
        expect(described_class.prepare(resource)).to match(
          data: resource
        )
      end
    end
  end
end
