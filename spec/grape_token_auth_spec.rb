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

  describe '.set_omniauth_prefix!' do
    let(:prefix_value) { 'someprefixvalue' }
    before do
      GrapeTokenAuth.configure { |c| c.omniauth_prefix = prefix_value }
      GrapeTokenAuth.set_omniauth_path_prefix!
    end

    it 'sets the OmniAuth prefix to the configured valued' do
      expect(OmniAuth.config.path_prefix).to eq prefix_value
    end
  end

  describe '.send_notification' do
    context 'with a notification type and opts' do
      it 'defers to a mailer class' do
        params = { to: 'h@h.com' }
        type = :confirmation_instructions
        message_double = double
        expect(GrapeTokenAuth::Mail).to receive(:initialize_message)
          .with(type, params)
          .and_return(message_double)
        expect(GrapeTokenAuth::Mail::SMTPMailer).to receive(:send!)
          .with(message_double, params)
        GrapeTokenAuth.send_notification(type, params)
      end
    end
  end

  describe '.setup!' do
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

  describe '.setup_warden!' do
    context 'when passed an instance of rack builder' do
      let(:rack_builder) { Rack::Builder.new }

      before do
        described_class.setup_warden!(rack_builder)
      end

      it 'sets the failure app to GrapeTokenAuth::UnauthorizedMiddleware' do
        rack_builder.run(lambda do |e|
          expect(e['warden'].config.failure_app)
            .to eq GrapeTokenAuth::UnauthorizedMiddleware
        end)
        rack_builder.call(env_with_params)
      end

      it 'sets the default scope to :user' do
        rack_builder.run(lambda do |e|
          expect(e['warden'].config.default_scope).to eq :user
        end)
        rack_builder.call(env_with_params)
      end
    end

    def env_with_params(path = '/', params = {}, env = {})
      method = params.delete(:method) || 'GET'
      env = { 'HTTP_VERSION' => '1.1',
              'REQUEST_METHOD' => "#{method}" }.merge(env)
      Rack::MockRequest.env_for("#{path}?#{Rack::Utils.build_query(params)}",
                                env)
    end
  end
end
