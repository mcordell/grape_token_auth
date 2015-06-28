require 'spec_helper'

module GrapeTokenAuth
  RSpec.describe AuthenticationHeader do
    let(:scope) { :user }
    let(:data)      { instance_double('AuthorizerData') }
    let(:user)      { FactoryGirl.create(:user) }
    let(:client_id) { 'clientid' }
    subject { AuthenticationHeader.new(data, scope, Time.now) }

    describe '.headers' do
      context 'when a valid resource has been stored' do
        context 'with a valid client id' do
          before do
            expect(data).to receive(:fetch_stored_resource).and_return(user)
            expect(data).to receive(:client_id).at_least(:once)
              .and_return(client_id)
          end

          it 'returns valid authentication header' do
            expect(subject.headers).to match(auth_header_format)
          end
        end

        context 'without a valid client_id' do
          before do
            expect(data).to receive(:fetch_stored_resource).and_return(user)
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
            expect(data).to receive(:fetch_stored_resource).and_return(nil)
          end

          it 'returns an empty hash' do
            expect(subject.headers).to eq({})
          end
        end
      end
    end
  end
end
