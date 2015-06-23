require 'spec_helper'

describe GrapeTokenAuth do
  it 'has a version number' do
    expect(GrapeTokenAuth::VERSION).not_to be nil
  end

  describe '#token_lifespan' do
    let(:lifespan) { 4545 }

    before do
      GrapeTokenAuth.configure do |config|
        config.token_lifespan = lifespan
      end
    end

    it 'defers to the stored configuration value' do
      expect(GrapeTokenAuth.token_lifespan).to eq 4545
    end
  end

  describe '#configure' do
    context 'when provided a block' do
      before do
        GrapeTokenAuth.configure do |config|
          config.token_lifespan = 4546
        end
      end

      it 'sets configuration values for the module' do
        expect(GrapeTokenAuth.configuration.token_lifespan).to eq 4546
      end
    end
  end
end
