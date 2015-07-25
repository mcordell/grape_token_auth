module GrapeTokenAuth
  describe ResourceFinder do
    describe '.find' do
      let!(:existing_user) { FactoryGirl.create(:user, nickname: 'pluto') }

      before do
        GrapeTokenAuth.configure do |c|
          c.mappings = { user: User }
        end
      end

      context 'with a valid scope' do
        context 'when params do not contain a valid finder key' do
          it 'return nil' do
            expect(ResourceFinder.find(:user, {})).to be_nil
          end
        end

        context 'when the default email key is present' do
          context 'and it matches an existing user' do
            let(:params) { { 'email' => existing_user.email } }

            it 'returns the user' do
              expect(ResourceFinder.find(:user, params)).to eq existing_user
            end
          end

          context 'and it does not matching an existing user' do
            let(:params) { { 'email' => 'somethingbodyelse@example.com' } }

            it 'returns nil' do
              expect(ResourceFinder.find(:user, params)).to be_nil
            end
          end

          context 'when the email is a case insensitive key' do
            before do
              User.case_insensitive_keys = [:email]
            end
            after { User.case_insensitive_keys = [] }

            context 'and the email has different casing' do
              let(:params) { { 'email' => existing_user.email.upcase } }

              it 'returns the user' do
                expect(ResourceFinder.find(:user, params)).to eq existing_user
              end
            end
          end
        end

        context 'when another authentication key is present' do
          before do
            GrapeTokenAuth.configure do |c|
              c.authentication_keys = [:nickname]
            end
          end

          after { GrapeTokenAuth.configuration = Configuration.new }

          context 'and it matches a user' do
            it 'returns existing user' do
              params = { nickname: 'pluto' }
              expect(ResourceFinder.find(:user, params)).to eq existing_user
            end
          end

          context 'and it does not match a user' do
            it 'returns nil' do
              params = { nickname: 'bluto' }
              expect(ResourceFinder.find(:user, params)).to be_nil
            end
          end
        end
      end

      context 'with an invalid scope' do
        it 'raises a ScopeUndefinedError' do
          expect { ResourceFinder.find(:man, {}) }
            .to raise_error ScopeUndefinedError
        end
      end
    end
  end
end
