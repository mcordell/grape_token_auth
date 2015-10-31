require 'spec_helper'

module GrapeTokenAuth
  RSpec.describe AuthenticationHeader do
    let(:scope)     { :user }
    let(:data)      { instance_double('GrapeTokenAuth::AuthorizerData') }
    let(:user)      { FactoryGirl.create(:user) }
    let(:client_id) { 'clientid' }
    subject { AuthenticationHeader.new(data, Time.now) }

    describe '.build_auth_headers' do
      context 'when supplied a Token and a uid' do
        let(:uid)   { 'some@uid.com' }
        let(:token) { Token.new }

        it 'returns a hash of the auth headers' do
          headers = described_class.build_auth_headers(token, uid)
          expect(headers).to match(auth_header_format(token.client_id))
          expect(headers['uid']).to eq uid
        end
      end
    end

    describe '#headers' do
      context 'when a valid resource has been stored' do
        before do
          expect(data).to receive(:first_authenticated_resource)
            .and_return(user)
        end

        context 'with a valid client id ' do
          before do
            expect(data).to receive(:client_id).at_least(:once)
              .and_return(client_id)
          end

          context 'and it is set to not change headers on each request' do
            before do
              credentials = user.create_new_auth_token(client_id)
              @token = credentials['access-token']
              expect(data).to receive(:token).and_return(@token)
              expect(GrapeTokenAuth)
                .to receive(:change_headers_on_each_request).and_return false
            end

            it 'returns valid authentication header' do
              expect(subject.headers).to match(auth_header_format(client_id))
            end

            it 'returns the same token in the headers' do
              expect(subject.headers['access-token']).to eq @token
            end
          end

          context 'and it is not a batch request' do
            before do
              user.create_new_auth_token(client_id)
              # age the token to get it outside of the batch window
              age_token(user, client_id)
            end

            it 'returns valid authentication header' do
              expect(subject.headers).to match(auth_header_format(client_id))
            end
          end

          context 'and it is a batch request' do
            before do
              credentials = user.create_new_auth_token(client_id)
              token = credentials['access-token']
              expect(data).to receive(:token).and_return(token)
              expect(user).to receive(:extend_batch_buffer)
                .with(token, client_id)
            end

            it 'returns empty headers' do
              expect(subject.headers).to eq({})
            end
          end
        end

        context 'without a valid client_id' do
          before do
            expect(data).to receive(:client_id).at_least(:once)
              .and_return(nil)
          end

          it 'returns valid authentication header' do
            expect(subject.headers).to eq({})
          end
        end
      end

      context 'when a valid resource has not been persisted' do
        context 'with a valid client id' do
          before do
            expect(data).to receive(:first_authenticated_resource)
              .and_return(nil)
          end

          it 'returns an empty hash' do
            expect(subject.headers).to eq({})
          end
        end
      end
    end
  end
end
