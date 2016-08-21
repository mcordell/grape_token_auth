# frozen_string_literal: true
module GrapeTokenAuth
  RSpec.describe OmniAuthHTMLBase do
    let(:invalid_error) { 'Invalid OmniAuthHTMLBase class' }
    describe '#render_html' do
      context 'when json_post_data is not defined on the class' do
        it 'raises an error' do
          expect { OmniAuthHTMLBase.new.render_html }
            .to raise_error(invalid_error)
        end
      end

      context "when json_post_data is defined and auth_origin_url isn't" do
        before do
          # Mock Subclass for OmniAuth base class test
          class SubclassFail < OmniAuthHTMLBase
            def json_post_data
            end
          end
        end

        it 'raises an error' do
          expect { SubclassFail.new.render_html }
            .to raise_error(invalid_error)
        end
      end

      context 'when json_post_data and auth_origin_url are defined' do
        let(:subclass) { ValidSubclass.new }

        before do
          # Mock Subclass for OmniAuth base class test
          class ValidSubclass < OmniAuthHTMLBase
            def json_post_data
            end

            def auth_origin_url
            end
          end
        end

        it 'does not raise an error' do
          expect { ValidSubclass.new.render_html }.not_to raise_error
        end

        it 'calls json_post_data' do
          expect(subclass).to receive(:json_post_data)
          subclass.render_html
        end

        it 'loads the omniauth response template' do
          template_path = File.join(
            File.expand_path('../../../../..', __FILE__),
            'lib/grape_token_auth/omniauth/response_template.html.erb')
          expect(File).to receive(:read).with(template_path).and_call_original
          subclass.render_html
        end
      end
    end
  end
end
