# frozen_string_literal: true
module GrapeTokenAuth
  describe Token do
    before { Timecop.freeze }
    after  { Timecop.return }

    subject(:token) { Token.new }

    describe 'initialization' do
      context 'when provided no arguments' do
        it 'generates a new client id' do
          expect(token.client_id).not_to be_nil
        end

        it 'sets its token' do
          expect(token.token).not_to be_nil
        end

        it 'sets its exipry to the current time + the token lifespan' do
          expect(GrapeTokenAuth).to receive(:token_lifespan).and_return(300)
          expect(token.expiry).to eq((Time.now + 300).to_i)
        end
      end

      context 'when provided a client_id' do
        subject(:token) { Token.new('clientidman') }

        it 'retains that client id' do
          expect(token.client_id).to eq 'clientidman'
        end

        context 'and a token' do
          subject(:token) { Token.new('clientidman', 'thisisatoken') }

          it 'retains that token' do
            expect(token.token).to eq 'thisisatoken'
          end

          context 'and an expiry' do
            subject(:token) { Token.new('clientidman', 'thisisatoken', 400) }

            it 'retains that expiry' do
              expect(token.expiry).to eq 400
            end
          end
        end
      end
    end

    describe '#to_s' do
      it 'returns its token' do
        expect(token.to_s).to eq token.token
      end
    end

    describe '#to_h' do
      it 'returns a hash containing it expiry and token hash' do
        expect(token.to_h).to match a_hash_including(
          token: token.to_password_hash, expiry: token.expiry)
      end

      it 'returns a hash containing updated_at set to Time.now' do
        expect(token.to_h[:updated_at]).to eq Time.now
      end
    end

    describe '#to_password_hash' do
      it 'returns its token as a BCrypt password hash' do
        expect(BCrypt::Password.new(token.to_password_hash))
          .to eq(token.to_s)
      end
    end
  end
end
