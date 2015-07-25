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
          expect { subject.scope_to_class(:user) }
            .to raise_error MappingsUndefinedError
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
  end
end
