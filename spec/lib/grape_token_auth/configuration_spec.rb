require 'spec_helper'

module GrapeTokenAuth
  describe Configuration do
    describe '#token_lifespan' do
      it 'defaults to two weeks' do
        expect(subject.token_lifespan).to eq 2.weeks
      end
    end

    describe '#batch_request_buffer_throttle' do
      it 'defaults to five seconds' do
        expect(subject.batch_request_buffer_throttle).to eq 5.seconds
      end
    end

    describe '#change_headers_on_each_request' do
      it 'defaults to true' do
        expect(subject.change_headers_on_each_request).to eq true
      end
    end

    describe '#mappings' do
      it 'returns a hash' do
        expect(subject.mappings).to be_a Hash
      end
    end

    describe '#redirect_whitelist' do
      it 'defaults to redirect_whitelist' do
        expect(subject.redirect_whitelist).to be_nil
      end
    end

    describe '#param_white_list' do
      it 'defaults to nil' do
        expect(subject.param_white_list).to be_nil
      end
    end

    describe '#authentication_keys' do
      it 'defaults to an array containing :email'  do
        expect(subject.authentication_keys).to eq [:email]
      end
    end

    describe '#scope_to_class' do
      context 'when scopes are not setup' do
        it 'throws an error' do
          message = 'GrapeTokenAuth mapping are undefined. Define your mappings' \
                    ' within the GrapeTokenAuth configuration'
          expect { subject.scope_to_class(:user) }
            .to raise_error MappingsUndefinedError, message
        end
      end

      context 'when the passed scope has been setup' do
        before { subject.mappings = { user: User } }

        it 'returns the mapped class' do
          expect(subject.scope_to_class(:user)).to eq User
        end
      end

      context 'when the passed scope has not been setup' do
        before { subject.mappings = { user: User } }

        it 'returns nil' do
          expect(subject.scope_to_class(:admin)).to be_nil
        end
      end
    end

    describe '#omniauth_prefix' do
      it "defaults to '/omniauth'" do
        expect(subject.omniauth_prefix).to eq '/omniauth'
      end
    end

    describe '#ignore_default_serialization_blacklist' do
      it 'defaults to false' do
        expect(subject.ignore_default_serialization_blacklist).to eq false
      end
    end

    describe '#additional_serialization_blacklist' do
      it 'defaults to an empty Array' do
        expect(subject.additional_serialization_blacklist).to eq []
      end
    end

    describe '#serialization_blacklist' do
      let(:default_blacklist) do
        GrapeTokenAuth::Configuration::SERIALIZATION_BLACKLIST
      end

      context 'when ignore_default_serialization_blacklist is false' do
        before { subject.ignore_default_serialization_blacklist = false }

        it 'inculdes the default blacklist' do
          expect(subject.serialization_blacklist).to include(*default_blacklist)
        end
      end

      context 'when ignore_default_serialization_blacklist is false' do
        before { subject.ignore_default_serialization_blacklist = true }

        it 'does not include the default blacklist' do
          expect(subject.serialization_blacklist)
            .not_to include(*default_blacklist)
        end
      end

      it 'includes all of the additional_serialization_blacklist' do
        additional = [:cat, :dog, :color]
        subject.additional_serialization_blacklist = additional
        expect(subject.serialization_blacklist).to include(*additional)
      end

      it 'returns an array of symbols' do
        subject.additional_serialization_blacklist = %w(cat dog color)
        expect(subject.serialization_blacklist).to all(be_a(Symbol))
      end
    end

    describe '#default_password_reset_url' do
      it 'defaults to nil' do
        expect(subject.default_password_reset_url).to be_nil
      end
    end

    describe '#smtp_configuration' do
      it 'defaults to an empty hash' do
        expect(subject.smtp_configuration).to eq({})
      end
    end

    describe '#secret' do
      it 'defaults to nil' do
        expect(subject.secret).to be_nil
      end
    end

    describe '#digest' do
      it 'defaults to SHA256' do
        expect(subject.digest).to eq 'SHA256'
      end
    end

    describe '#key_generator' do
      context 'when secret has not been set' do
        before { subject.secret = nil }

        it 'raises an error' do
          expect { subject.key_generator }.to raise_error(SecretNotSet)
        end
      end

      it 'returns a CachingKeyGenerator' do
        subject.secret = 'blahblahblah'
        expect(subject.key_generator).to be_a CachingKeyGenerator
      end
    end

    describe '#messages' do
      it 'defaults to Mailer::DEFAULT_MESSAGES' do
        expect(subject.messages).to eq Mailer::DEFAULT_MESSAGES
      end
    end

    describe '#from_address' do
      it 'defaults to nil' do
        expect(subject.from_address).to be_nil
      end
    end
  end
end
