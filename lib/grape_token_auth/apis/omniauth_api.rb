# frozen_string_literal: true
module GrapeTokenAuth
  # Module that contains the majority of the OmniAuth functionality. This module
  # can be included in a Grape::API class that defines a resource_scope and
  # therefore have all of the functionality with a given resource (mapping).
  module OmniAuthAPICore
    def self.included(base)
      base.helpers do
        def auth_hash
          @auth_hash ||= begin
            hash = request.env['rack.session'].delete('gta.omniauth.auth')

            # While using Grape on Rails, #session is an ActionDispatch::Request::Session class,
            # which does not preserve OmniAuth::AuthHash class @ 'gta.omniauth.auth' key,
            # converting it to Hash. Restoring
            hash.kind_of?(::OmniAuth::AuthHash) ? hash : ::OmniAuth::AuthHash.new(hash)
          end
        end

        def omniauth_params
          @omniauth_params ||= request.env['rack.session']
                               .delete('gta.omniauth.params')
        end

        def render_html(html)
          env['api.format'] = :html
          content_type 'text/html; charset=utf-8'
          html
        end

        def redirect_or_render(success_html)
          if %w(inAppBrowser newWindow).include?(success_html.window_type)
            render_html(success_html.render_html)
          elsif success_html.auth_origin_url
            # default to same-window implementation, which forwards back to
            # auth_origin_url build and redirect to destination url
            redirect success_html.full_redirect_url
          else
            # there SHOULD always be an auth_origin_url, but if someone does
            # something silly like coming straight to this url or refreshing the
            # page at the wrong time, there may not be one. In that case, just
            # render in plain text the error message if there is one or
            # otherwisei a generic message.
            fallback_render 'An error occurred'
          end
        end

        def fallback_render(text)
          render_html <<-EOD
            <html>
                    <head></head>
                    <body>
                            #{text}
                    </body>
            </html>
          EOD
        end
      end

      base.desc 'resource redirector for initial auth attempt' do
        detail <<-EOD
        Sets up the proper resource classes as a query parameter that is then
        passed along to the proper OmniAuth provider app.
        EOD
      end
      base.get ':provider' do
        qs = CGI.parse(request.env['QUERY_STRING'])
        qs['resource_class'] = [base.resource_scope]
        query_params = qs.each_with_object({}) do |args, hsh|
          hsh[args[0]] = args[1].first
        end.to_param
        omni_prefix = ::OmniAuth.config.path_prefix
        path = "#{omni_prefix}/#{params[:provider]}?#{query_params}"
        redirect path
      end

      base.desc 'OmniAuth success endpoint'
      base.get ':provider/callback' do
        fail unless omniauth_params
        fail unless auth_hash
        resource_class = GrapeTokenAuth.configuration
                         .scope_to_class(base.resource_scope)
        success_html = OmniAuthSuccessHTML.build(resource_class,
                                                 auth_hash,
                                                 omniauth_params)
        if success_html.persist_oauth_attributes!
          data = AuthorizerData.load_from_env_or_create(env)
          data.store_resource(success_html.resource, base.resource_scope)
          redirect_or_render(success_html)
        else
          status 500
        end
      end
    end
  end

  # "Empty" OmniAuth API where OmniAuthAPICore is mounted, defaults to a :user
  # resource class
  class OmniAuthAPI < Grape::API
    class << self
      def resource_scope
        :user
      end
    end

    include OmniAuthAPICore
  end

  # Upon a callback from the OmniAuth provider this API (endpoint) provides
  # routing to the indvidual resource class's OmniAuthAPI callback endpoint.
  # This API eventually gets mounted at /OMNIAUTH_PREFIX/ where OMNIAUTH prefix
  # is configured in GrapeTokenAuth
  class OmniAuthCallBackRouterAPI < Grape::API
    helpers do
      def redirect_route_from_api(api, provider)
        prefix = api.routes.find do |r|
          grape_version = Grape::VERSION.split('.').map(&:to_i)
          path = (grape_version[0] > 0 || grape_version[1] >= 16) ? r.origin : r.path
          %r{/:provider/callback}.match(path)
        end.path.split(%r{/:provider})[0]
        Pathname.new(prefix).join(provider, 'callback.json').to_s
      end

      def resource_class_from_auth
        scope = request.env.fetch('omniauth.params', {})['resource_class']
        return unless scope
        GrapeTokenAuth.configuration.scope_to_class(scope.underscore.to_sym)
      end

      def session
        request.env['rack.session']
      end
    end
    desc 'Callback endpoint that redirects to individual resource callbacks'
    get ':provider/callback' do
      # derive target api from 'resource_class' param, which was set
      # before authentication.
      resource_class = resource_class_from_auth
      api = GrapeTokenAuth.const_get("#{resource_class}OmniAuthAPI") ||
            OmniAuthAPI

      # preserve omniauth info for success route. ignore 'extra' in twitter
      session['gta.omniauth.auth'] = request.env['omniauth.auth']
                                     .except('extra')
      session['gta.omniauth.params'] = request.env['omniauth.params']

      redirect redirect_route_from_api(api, params[:provider])
    end

    get '/failure' do
      env['api.format'] = :html
      content_type 'text/html; charset=utf-8'
      OmniAuthFailureHTML.new(params[:message] || params['message']).render_html
    end
  end
end
