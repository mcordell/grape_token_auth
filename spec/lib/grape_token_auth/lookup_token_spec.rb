# frozen_string_literal: true
module GrapeTokenAuth
  RSpec.describe LookupToken do
    describe '.friendly_token' do
      subject(:returned) { described_class.friendly_token }

      describe 'returned string' do
        it 'is 20 characters long' do
          expect(returned.length).to eq 20
        end

        it { is_expected.to be_url_safe }

        it "does not contain 'l' 'I' 'O' or 0" do
          expect(returned).not_to match(/[lIO0]/)
        end
      end

      context 'when passed a length' do
        subject(:returned) { described_class.friendly_token(12) }

        describe 'returned string' do
          it 'is that length' do
            expect(returned.length).to eq 12
          end
        end
      end
    end

    describe '.digest' do
      context 'with a column and a value' do
        before do
          GrapeTokenAuth.configure do |c|
            c.secret = 'thissecretwouldberandom'
          end
        end

        context 'using the key generator on configuration' do
          let(:key) { 'columnkey' }
          before do
            key_generator = GrapeTokenAuth.configuration.key_generator
            allow(key_generator).to receive(:generate_key).and_return(key)
          end

          it 'returns a SHA256 digest of the key and value' do
            value = 'thisisarawvalue'
            expected = OpenSSL::HMAC.hexdigest('SHA256', 'columnkey', value)
            expect(described_class.digest('somecolumn', value)).to eq expected
          end
        end
      end

      context 'without a value' do
        subject { described_class.digest('somecolumn', nil) }
        it { is_expected.to be_nil }
      end
    end

    describe '.generate' do
      context 'with an authenticatable class and a column' do
        let(:token)                 { 'afriendlytoken' }
        let(:encoded)               { 'encodedgolbbidygook' }
        let(:column)                { 'rememberable_token' }
        let(:authenticatable_class) { double('authenticatable') }

        before do
          GrapeTokenAuth.configure do |c|
            c.secret = 'thissecretwouldberandom'
          end

          allow(described_class).to receive(:friendly_token).and_return(token)
          allow(described_class).to receive(:digest).with(column, token)
            .and_return(encoded)
          allow(authenticatable_class).to receive(:exists_in_column?)
            .and_return(false)
        end

        subject(:returned) do
          described_class.generate(authenticatable_class, column)
        end

        it 'returns a raw token and the encoded token in an array' do
          is_expected.to eq [token, encoded]
        end
      end
    end
  end
end
