module GrapeTokenAuth
  describe ApiHelpers do
    context 'with mappings defined' do
      before do
        GrapeTokenAuth.configure do |c|
          c.mappings = { user: User, dog: Class.new }
        end
      end

      describe 'upon inclusion in a class' do
        before do
          class XY
            include GrapeTokenAuth::ApiHelpers
          end
        end

        subject { XY.new }

        it { is_expected.to respond_to :authorizer_data }
        it { is_expected.to respond_to :authenticated? }

        it 'creates current_resource helper methods for each scope' do
          expect(subject).to respond_to :current_user
          expect(subject).to respond_to :current_man
        end

        it 'creates authenticate_resource! helper methods for each scope' do
          expect(subject).to respond_to :authenticate_user!
          expect(subject).to respond_to :authenticate_man!
        end
      end

      describe '.mount_registration' do
        before do
          class SomeAPI < Grape::API
            format :json
            include GrapeTokenAuth::ApiHelpers
          end
        end

        after { GrapeTokenAuth.send(:remove_const, :SomeAPI) }

        context 'with no arguments' do
          before do
            SomeAPI.mount_registration
          end

          it 'mounts the user RegistrationAPI at root path' do
            expect(SomeAPI).to have_route('POST', '/(.json)')
          end
        end

        context 'when the params contains a to: key' do
          before do
            SomeAPI.mount_registration(to: '/auth')
          end

          it 'mounts the user RegistrationAPI to the path of the value' do
            expect(SomeAPI).to have_route('POST', '/auth(.json)')
          end
        end

        context 'when the for param contains an undefined scope' do
          it 'raises a ScopeUndefinedError' do
            expect { SomeAPI.mount_registration(for: :cat) }
              .to raise_error ScopeUndefinedError
          end
        end

        context 'when the for param contains a valid scope' do
          before do
            SomeAPI.mount_registration(for: :dog)
          end

          it 'creates a subclass of the registrable API with that scope' do
            expect(GrapeTokenAuth::DogRegistrationAPI.resource_scope).to eq :dog
          end
        end
      end

      describe '.mount_sessions' do
        before do
          class SomeAPI < Grape::API
            format :json
            include GrapeTokenAuth::ApiHelpers
          end
        end

        after { GrapeTokenAuth.send(:remove_const, :SomeAPI) }

        context 'with no arguments' do
          before do
            SomeAPI.mount_sessions
          end

          it 'mounts the user RegistrationAPI at root path' do
            expect(SomeAPI).to have_route('POST', '/sign_in(.json)')
          end
        end

        context 'when the params contains a to: key' do
          before do
            SomeAPI.mount_sessions(to: '/auth')
          end

          it 'mounts the user RegistrationAPI to the path of the value' do
            expect(SomeAPI).to have_route('POST', '/auth/sign_in(.json)')
          end
        end

        context 'when the for param contains an undefined scope' do
          it 'raises a ScopeUndefinedError' do
            expect { SomeAPI.mount_sessions(for: :cat) }
              .to raise_error ScopeUndefinedError
          end
        end

        context 'when the for param contains a valid scope' do
          before do
            SomeAPI.mount_sessions(for: :dog)
          end

          it 'creates a subclass of the registrable API with that scope' do
            expect(GrapeTokenAuth::DogRegistrationAPI.resource_scope).to eq :dog
          end
        end
      end
    end
  end
end
