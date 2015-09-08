RSpec.shared_examples 'a grape token auth email' do
  let(:message) { described_class.new(to: to) }
  let(:from) { 'from@example.com' }
  let(:to) { 'test@example.com' }
  let(:msg_subject) { 'Message subject' }
  let(:text_body) { 'Message body' }
  let(:html_body) { '<html><body>Message body</body></html>' }
  subject(:delivery) { ::Mail::TestMailer.deliveries.last }

  before do
    GrapeTokenAuth.configuration.from_address = from
    message.subject = msg_subject
    message.text_body = text_body
    message.html_body = html_body
    message.prepare!
    message.send
  end

  it 'is a multipart email' do
    expect(delivery.parts.count).to be > 1
  end
end
