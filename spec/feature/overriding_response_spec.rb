class OnlyIdPreparer
  def self.prepare(resource)
    {
      id: resource.id
    }
  end
end

RSpec.describe 'overriding resource response' do
  before do
    @b_prep = nil
    GrapeTokenAuth.configure do |config|
      @b_prep = config.resource_preparer
      config.resource_preparer = OnlyIdPreparer
    end
  end

  let(:last_user) { User.last }
  let(:data) { JSON.parse(response.body) }

  after { GrapeTokenAuth.configure { |c| c.resource_preparer = @b_prep } }

  let(:valid_attributes) do
    {
      email: 'test@example.com',
      password: 'secret123',
      password_confirmation: 'secret123'
    }
  end

  it 'allows modifying the response of the resource' do
    post '/auth', valid_attributes
    expect(data).to match(
      'id' => last_user.id
    )
  end
end
