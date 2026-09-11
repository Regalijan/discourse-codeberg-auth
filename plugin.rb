# frozen_string_literal: true

# name: discourse-codeberg-auth
# about: Allows users to sign in with their Codeberg account
# version: 1.0.0
# authors: Regalijan
# url: https://github.com/Regalijan/discourse-codeberg-auth

enabled_site_setting :enable_codeberg_login

require 'base64'
require_relative 'lib/validators/CodebergLoginToggle'

register_svg_icon 'codeberg-auth-codeberg-logo' if respond_to?(:register_svg_icon)

class CodebergAuthenticator < Auth::ManagedAuthenticator
  class CodebergStrategy < OmniAuth::Strategies::OAuth2
    option :name, 'codeberg'
    option :scope, 'openid profile email'

    option :client_options,
           site: 'https://codeberg.org/login/oauth/',
           authorize_url: 'authorize',
           token_url: 'access_token'

    option :authorize_options, %i[scope]

    uid { raw_info['sub'] }

    info do
      {
        name: raw_info['name'],
        email: raw_info['email_verified'] ? raw_info['email'] : nil,
        image: raw_info['picture']
      }
    end

    extra { { 'raw_info' => raw_info } }

    def callback_url
      full_host + script_name + callback_path
    end

    def name
      'codeberg'
    end

    def raw_info
      @raw_info ||= JSON.parse(
        Base64.urlsafe_decode64(
          access_token['id_token'].split('.')[1]
        )
      )
    end
  end

  def enable_setting
    :enable_codeberg_login
  end

  def required_settings
    %i[codeberg_client_id codeberg_secret]
  end

  def name
    'codeberg'
  end

  def primary_email_verified?(auth_token)
    auth_token['extra']['raw_info']['email_verified']
  end

  def register_middleware(omniauth)
    omniauth.provider CodebergStrategy,
                      setup: lambda { |env|
                        strategy = env['omniauth.strategy']
                        strategy.options[:client_id] = SiteSetting.codeberg_client_id
                        strategy.options[:client_secret] = SiteSetting.codeberg_secret
                      }
  end
end

auth_provider authenticator: CodebergAuthenticator.new, icon: 'codeberg-auth-codeberg-logo'
