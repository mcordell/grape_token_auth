module GrapeTokenAuth
  RSpec.describe Utility do
    describe '.humanize' do
      subject(:result) { described_class.humanize(snake_cased) }

      context 'when passed a two work snake cased symbol' do
        let(:snake_cased) { :camel_case }

        it 'returns a capitalized camel case string' do
          is_expected.to eq('CamelCase')
        end
      end

      context 'when passed a muli-word snake cased string' do
        let(:snake_cased) { 'camel_case' }

        it 'returns a capitalized camel case string' do
          is_expected.to eq('CamelCase')
        end
      end

      context 'when passed a single snake cased word' do
        let(:snake_cased) { 'camel' }

        it 'returns a capitalized camel case string' do
          is_expected.to eq('Camel')
        end
      end

      context 'when passed a capitalized single word' do
        let(:snake_cased) { 'Camel' }

        it 'returns a capitalized camel case string' do
          is_expected.to eq('Camel')
        end
      end
    end
  end
end
