module GrapeTokenAuth
  describe ResourceCreator do
    let(:configuration) { instance_double(Configuration) }
    let(:basic_attributes) do
      { 'email' => 'user@example.com', 'password' => 'password',
        'password_confirmation' => 'password' }
    end

    describe 'initialization' do
      let(:rc) { ResourceCreator.new({}, configuration, :admin) }

      it 'accepts a params, configuration, and scope' do
        expect(rc.scope).to eq(:admin)
      end

      context 'when scope is not provided' do
        let(:rc) { ResourceCreator.new({}, configuration) }

        it 'defaults to :user' do
          expect(rc.scope).to eq(:user)
        end
      end
    end

    describe '#create!' do
      let(:rc) { ResourceCreator.new({}, configuration, :user) }
      context 'when scope is undefined' do
        before { allow(configuration).to receive(:scope_to_class).with(:user) }

        it 'raises a ScopeUndefinedError' do
          expect { rc.create! }.to raise_error(ScopeUndefinedError)
        end
      end

      context 'when scope is defined' do
        before do
          allow(configuration).to receive(:scope_to_class).with(:user)
            .and_return(User)
        end

        context 'when the params do not contain email and password params' do
          it 'returns false' do
            expect(rc.create!).to be false
          end

          it 'sets errors noting missing params' do
            rc.create!
            expect(rc.errors).to include('email is required',
                                         'password is required',
                                         'password_confirmation is required')
          end
        end

        context 'when standard params are provided' do
          let(:rc) do
            ResourceCreator.new(basic_attributes, configuration, :user)
          end

          it "creates a resource of the scope's matching class" do
            expect { rc.create! }.to change(User, :count).by 1
          end

          it 'returns the newly created resource' do
            returned = rc.create!
            expect(returned).to eq User.last
          end
        end

        context 'when standard param keys are symbols' do
          let(:valid_user_attributes) do
            { email: 'user@example.com', password: 'password',
              password_confirmation: 'password' }
          end

          let(:rc) do
            ResourceCreator.new(valid_user_attributes, configuration, :user)
          end

          it "creates a resource of the scope's matching class" do
            expect { rc.create! }.to change(User, :count).by 1
          end
        end

        context 'when the created resource is not valid' do
          let(:attrs) { basic_attributes.merge(operating_thetan: -1) }
          let(:rc) { ResourceCreator.new(attrs, configuration, :user) }

          before do
            GrapeTokenAuth.configure do |config|
              config.param_white_list = { user: [:operating_thetan] }
            end
          end

          it 'returns false' do
            expect(rc.create!).to be false
          end

          it 'adds the validation messages to its errors' do
            rc.create!
            expect(rc.errors)
              .to include 'operating_thetan must be greater than -1'
          end
        end
      end
    end
  end
end
