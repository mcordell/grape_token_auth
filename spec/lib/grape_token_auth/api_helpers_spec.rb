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

        it 'defines class method mount_registration' do
          expect(subject.class).to respond_to :mount_registration
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
            route = SomeAPI.routes[0]
            expect(route.route_path).to eq '/(.json)'
            expect(route.route_method).to eq 'POST'
          end
        end

        context 'when the params contains a to: key' do
          before do
            SomeAPI.mount_registration(to: '/auth')
          end

          it 'mounts the user RegistrationAPI to the path of the value' do
            route = SomeAPI.routes[0]
            expect(route.route_path).to eq '/auth(.json)'
            expect(route.route_method).to eq 'POST'
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
    end
  end
end
