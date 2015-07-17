module GrapeTokenAuth
  describe ApiHelpers do
    context 'with mappings defined' do
      before do
        GrapeTokenAuth.configure do |c|
          c.mappings = { user: User, man: Man }
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

        it 'defines class method mount_registerable' do
          expect(subject.class).to respond_to :mount_registerable
        end
      end
    end
  end
end
