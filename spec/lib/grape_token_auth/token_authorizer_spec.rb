require 'spec_helper'

module GrapeTokenAuth
  RSpec.describe TokenAuthorizer do
    let(:data) { instance_double('AuthorizerData') }

    subject { TokenAuthorizer.new(data) }

    describe '.authenticate_from_token' do
      context 'when scopes have not been setup' do
        before { setup_scopes({}) }

        it 'raises an error' do
          expect { subject.authenticate_from_token(:user) }
            .to raise_error MappingsUndefinedError
        end
      end

      context 'when passed scope is missing' do
        before { setup_scopes(user: User) }

        it 'returns nil' do
          expect(subject.authenticate_from_token(:horse)).to be_nil
        end
      end

      context 'when passed scope is present' do
        before { setup_scopes(user: User) }

        context 'and authorizer data does not have valid prerequistes' do
          let(:data) do
            instance_double('AuthorizerData',
                            token_prerequisites_present?: false)
          end

          it 'returns nil' do
            expect(subject.authenticate_from_token(:user)).to be_nil
          end
        end

        context 'and data has valid pre-requisites but an invalid uid' do
          let(:data) do
            instance_double('AuthorizerData',
                            token_prerequisites_present?: true, uid: 'bad')
          end
          before do
            expect(User).to receive(:find_by_uid).with('bad').and_return(nil)
          end

          it 'returns nil' do
            expect(subject.authenticate_from_token(:user)).to be_nil
          end
        end

        context 'and data has valid prerequistes' do
          context 'but an invalid token for the user and client id' do
            let(:user) { instance_double('User') }
            let(:data) do
              instance_double('AuthorizerData',
                              token_prerequisites_present?: true, uid: 'good',
                              client_id: 'client', token: 'bad')
            end

            before do
              expect(User).to receive(:find_by_uid).with('good')
                .and_return(user)
              expect(user).to receive(:valid_token?).with('bad', 'client')
                .and_return(false)
            end

            it 'returns nil' do
              expect(subject.authenticate_from_token(:user)).to be_nil
            end
          end

          context 'and a valid token for the user and client' do
            let(:user) { instance_double('User') }
            let(:data) do
              instance_double('AuthorizerData',
                              token_prerequisites_present?: true, uid: 'good',
                              client_id: 'client', token: 'good')
            end

            before do
              expect(User).to receive(:find_by_uid).with('good')
                .and_return(user)
              expect(user).to receive(:valid_token?).with('good', 'client')
                .and_return(true)
            end

            it 'returns the user' do
              expect(subject.authenticate_from_token(:user)).to eq user
            end
          end
        end
      end
    end

    private

    def setup_scopes(scopes)
      GrapeTokenAuth.configure do |config|
        config.mappings = scopes
      end
    end
  end
end
