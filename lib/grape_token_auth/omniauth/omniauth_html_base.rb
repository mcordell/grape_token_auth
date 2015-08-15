require 'erb'
require 'json'

module GrapeTokenAuth
  class OmniAuthHTMLBase
    def render_html
      unless respond_to?(:json_post_data) && respond_to?(:auth_origin_url)
        fail 'Invalid OmniAuthHTMLBase class'
      end
      template.result(binding)
    end

    private

    def template_path
      File.expand_path('../response_template.html.erb', __FILE__)
    end

    def template
      ERB.new(File.read(template_path))
    end
  end
end
