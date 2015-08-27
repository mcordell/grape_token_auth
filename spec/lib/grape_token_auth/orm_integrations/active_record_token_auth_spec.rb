require 'spec_helper'

module GrapeTokenAuth
  module ActiveRecord
    RSpec.describe TokenAuth do
      subject { FactoryGirl.build(:user) }

      it { is_expected.to respond_to :while_record_locked }

      describe '#create_new_auth_token' do
        let(:token) { 'blahblah' }
        let(:client_id) { 'someclientid' }
        let(:token_lifespan) { 3600 }
        before do
          Timecop.freeze
          expect(GrapeTokenAuth).to receive(:token_lifespan).at_least(:once)
            .and_return(token_lifespan)
          expect(BCrypt::Password).to receive(:create).at_least(:once)
            .and_return(token)
          @returned_hash =  subject.create_new_auth_token(client_id)
        end

        after do
          Timecop.return
        end

        describe 'the returned hash' do
          it 'matches the authentication header format' do
            expect(@returned_hash).to match(auth_header_format(client_id))
          end
        end

        it 'returned expiry is the time currently plus the token lifespan' do
          expiry_time = (Time.now + token_lifespan).to_i
          expect(@returned_hash['expiry']).to eq expiry_time
        end

        it 'persists the token info under the client id in the users tokens' do
          subject.reload
          expect(subject.tokens[client_id]).to match(
            'token'      => token,
            'expiry'     => a_kind_of(Integer),
            'updated_at' => a_kind_of(String),
            'last_token' => nil
          )
        end

        context 'when the user had a token previously for the same client_id' do
          let!(:old_token_hash) do
            subject.reload
            subject.tokens[client_id]['token']
          end

          before { subject.create_new_auth_token(client_id) }

          it 'stores the previous token hash under the last_token key for the client_id' do
            subject.reload
            expect(subject.tokens[client_id]['last_token']).to eq old_token_hash
          end
        end

        context 'when passed a client_id' do
          let(:client_id) { 'client_id' }

          it 'returns the same client_id in its returned headers' do
            returned = subject.create_new_auth_token(client_id)
            expect(returned['client']).to eq client_id
          end
        end

        context 'when not passed a client_id' do
          it 'returns a URL safe randomly generated client_id' do
            returned = subject.create_new_auth_token
            expect(returned['client']).to match(/^[a-zA-Z0-9_-]*$/)
          end
        end
      end

      describe '#valid_token?' do
        let(:credentials_hash)  { subject.create_new_auth_token }
        let(:valid_token)       { credentials_hash['access-token'] }
        let(:valid_client_id)   { credentials_hash['client'] }
        let(:invalid_token)     { 'invalid' }
        let(:invalid_client_id) { 'invalid' }

        context 'when passed a valid token and client id pair' do
          it 'returns true' do
            expect(subject.valid_token?(valid_token, valid_client_id))
              .to eq true
          end
        end

        context 'when passed a valid token with an invalid client id' do
          it 'returns false' do
            expect(subject.valid_token?(valid_token, invalid_client_id))
              .to eq false
          end
        end

        context 'when passed a invalid token with a valid client id' do
          it 'returns false' do
            expect(subject.valid_token?(invalid_token, valid_client_id))
              .to eq false
          end
        end

        context 'when passed a invalid token with an invalid client id' do
          it 'returns false' do
            expect(subject.valid_token?(invalid_token, invalid_client_id))
              .to eq false
          end
        end

        skip 'when within the batch buffer window' do
        end
      end

      describe '#extend_batch_buffer' do
        before do
          Timecop.freeze
          credentials_hash = subject.create_new_auth_token
          @client_id = credentials_hash['client']
          token = credentials_hash['access-token']
          subject.reload
          @first_updated_at = subject.tokens[@client_id]['updated_at']
          Timecop.freeze(Time.now + 1.hour)
          @returned = subject.extend_batch_buffer(token, @client_id)
        end

        after { Timecop.return }

        context 'when provided an existing client id and token' do
          it 'returns auth headers' do
            expect(@returned).to match auth_header_format(@client_id)
          end

          it 'updates the updated_at time to now' do
            subject.reload
            expect(DateTime.parse(subject.tokens[@client_id]['updated_at']))
              .to eq(DateTime.parse(@first_updated_at) + 1.hour)
          end
        end
      end

      describe 'included class methods' do
        subject { User }

        it { is_expected.to respond_to :case_insensitive_keys }
        it { is_expected.to respond_to :case_insensitive_keys= }
      end

      describe 'password confirmation' do
        context 'when the confimation does not match the password' do
          before do
            subject.password = 'password1'
            subject.password_confirmation = 'not_password'
          end

          it do
            is_expected.not_to be_valid
          end
        end

        context 'when the password is nil' do
          before do
            subject.password = nil
            subject.password_confirmation = nil
          end

          it do
            is_expected.not_to be_valid
          end
        end
      end

      describe 'email validation' do
        context 'when the email is not valid' do
          before { subject.email = 'false_email@' }

          it { is_expected.not_to be_valid }
        end
      end

      describe 'duplicate email' do
        let!(:email_user) { FactoryGirl.create(:user) }

        context 'with the same provider' do
          subject { FactoryGirl.build(:user, email: email_user.email) }

          it { is_expected.not_to be_valid }
        end

        context 'with a different provider' do
          subject do
            FactoryGirl.build(:user, provider: 'facebook',
                                     email: email_user.email)
          end

          it { is_expected.to be_valid }
        end
      end

      describe 'syncing of email and uid on update' do
        let(:user) do
          FactoryGirl.create(:user, uid: 'dude@apple.co',
                                    email: 'dude@apple.co')
        end
        let(:new_email) { 'guy@happy.com' }

        context 'when the email changes' do
          before do
            user.update(email: new_email)
            user.reload
          end

          it 'changes the uid to match the email' do
            expect(user.uid).to eq new_email
          end
        end
      end

      describe 'serialization' do
        subject(:user) { FactoryGirl.create(:user) }

        it 'does not include anything in the configuration blacklist' do
          blacklist = GrapeTokenAuth::Configuration::SERIALIZATION_BLACKLIST
          expect(user.as_json.keys.map(&:to_sym))
            .not_to include(*blacklist)
        end
      end

      describe '#send_reset_password_instructions' do
        let(:token)    { 'thistokenwasgenerated' }
        let(:encoded)  { 'thisisencoded' }
        let!(:user)    { FactoryGirl.create(:user) }
        let(:opts)     { {} }

        before do
          Timecop.freeze
          allow(LookupToken).to receive(:generate).and_return([token, encoded])
          @returned = user.send_reset_password_instructions(opts)
          user.reload
        end

        after  { Timecop.return }

        it 'sets the reset_password_token encoded token' do
          expect(user.reset_password_token).to eq encoded
        end

        it 'returns the token' do
          expect(@returned).to eq token
        end

        it 'sets the reset_password_sent_at to now' do
          expect(user.reset_password_sent_at).to eq Time.now
        end

        describe 'email to be sent' do
          it 'sends an email with the token and the config set to default' do
            notification_opts = {
              token: token,
              client_config: 'default'
            }
            expect(GrapeTokenAuth).to receive(:send_notification)
              .with(:reset_password_instructions, notification_opts)
            user.send_reset_password_instructions({})
          end
        end
      end

      describe '.exists_in_column?' do
        context 'when supplied a column where a value already exists' do
          let!(:user) { FactoryGirl.create(:user, email: 'blah@example.com') }

          it 'returns true' do
            expect(User.exists_in_column?(:email, 'blah@example.com'))
              .to be true
          end
        end

        context 'when supplied a column where the value does not exist' do
          it 'returns false' do
            expect(User.exists_in_column?(:email, 'doesntexist@example.com'))
              .to be false
          end
        end
      end
    end
  end
end
