# frozen_string_literal: true
module GrapeTokenAuth
  describe ResourceUpdater do
    let(:configuration) { instance_double(Configuration) }
    let(:existing_user) { FactoryGirl.create(:user) }

    context '#update!' do
      let(:updater) do
        ResourceUpdater.new(existing_user, {}, configuration, :user)
      end

      context 'when scope is undefined' do
        before { allow(configuration).to receive(:scope_to_class).with(:user) }

        it 'raises a ScopeUndefinedError' do
          expect { updater.update! }.to raise_error(ScopeUndefinedError)
        end
      end

      context 'when scope is defined' do
        before do
          allow(configuration).to receive(:scope_to_class).with(:user)
            .and_return(User)
        end

        context 'when an email is provided' do
          let(:new_email) { 'somenewemail@apple.com' }

          let(:updater) do
            ResourceUpdater.new(existing_user, { 'email' => new_email },
                                configuration, :user)
          end

          before do
            @returned = updater.update!
          end

          it 'returns the updated resource' do
            expect(@returned).to eq existing_user
          end

          it 'updates the email' do
            existing_user.reload
            expect(existing_user.email).to eq new_email
          end
        end

        context 'when the updated resource is not valid' do
          let(:attrs) { { operating_thetan: -1 } }
          let(:updater) do
            ResourceUpdater.new(existing_user, attrs, configuration, :user)
          end

          before do
            GrapeTokenAuth.configure do |config|
              config.param_white_list = { user: [:operating_thetan] }
            end
          end

          it 'returns false' do
            expect(updater.update!).to be false
          end

          it 'adds the validation messages to its errors' do
            updater.update!
            expect(updater.errors)
              .to include 'operating_thetan must be greater than -1'
          end
        end
      end

      describe 'case insensitive keys' do
        context "when the case_insensitive_keys have been defined on the resource's class" do
          before do
            allow(configuration).to receive(:scope_to_class).with(:user)
              .and_return(User)
            User.case_insensitive_keys = [:email]
          end

          it 'downcases the value of those keys' do
            attrs   = { email: 'ABAcD@example.com' }
            updater = ResourceUpdater.new(existing_user, attrs,
                                          configuration, :user)
            updater.update!
            existing_user.reload
            expect(existing_user.email).to eq 'abacd@example.com'
          end
        end
      end
    end
  end
end
