# frozen_string_literal: true
RSpec.shared_examples 'a grape token auth email' do
  it { is_expected.to respond_to :text_body }
  it { is_expected.to respond_to :html_body }
end

RSpec.shared_examples 'a grape token auth mailer' do
  subject(:mailer) { described_class.new(double(), {}) }

  it 'responds to .send!' do
    expect(described_class).to respond_to :send!
  end

  it { is_expected.to respond_to :prepare_email! }
  it { is_expected.to respond_to :send_mail }
  it { is_expected.to respond_to :valid_options? }
end

RSpec.shared_examples 'a resource preparer' do
  describe '.prepare' do
    it 'accepts a resource argumetn' do
      expect { described_class.prepare(double('resource')) }.not_to raise_error
    end
  end
end
