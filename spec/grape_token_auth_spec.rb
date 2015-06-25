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

  describe '#setup!' do
    context 'when passed a block' do
      before do
        GrapeTokenAuth.setup! do |config|
          config.token_lifespan = 4546
        end
      end

      it 'sets configuration values for the module' do
        expect(GrapeTokenAuth.configuration.token_lifespan).to eq 4546
      end
    end

    it 'adds the auth strategy to grape' do
      GrapeTokenAuth.setup!
      strategies = Grape::Middleware::Auth::Strategies.auth_strategies.keys
      expect(strategies).to include(:grape_devise_token_auth)
    end
  end
end
