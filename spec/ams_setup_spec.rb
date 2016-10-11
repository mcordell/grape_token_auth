RSpec.describe 'user ams serializer' do
  it 'serializes as expected' do
    user = User.create!(email: 'surpher@gmail.com', name: 'michael',
                        operating_thetan: 12, password: 'test',
                        password_confirmation: 'test')
    options = {}
    serializable_resource = ActiveModelSerializers::SerializableResource.new(user, options)
    model_json = serializable_resource.to_json
    expect(model_json).to eq("{\"id\":#{user.id},\"name\":\"#{user.name}\"}")
  end
end
