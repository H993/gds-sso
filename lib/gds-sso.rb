require 'rails'

require 'gds-sso/config'
require 'gds-sso/warden_config'
require 'omniauth'
require 'omniauth-gds'

module GDS
  module SSO
    autoload :FailureApp,        'gds-sso/failure_app'
    autoload :ControllerMethods, 'gds-sso/controller_methods'
    autoload :User,              'gds-sso/user'
    autoload :ApiAccess,         'gds-sso/api_access'

    # User to return as logged in during tests
    mattr_accessor :test_user

    def self.config
      yield GDS::SSO::Config
    end

    class Engine < ::Rails::Engine
      # Force routes to be loaded if we are doing any eager load.
      # TODO - check this one - Stolen from Devise because it looked sensible...
      config.before_eager_load { |app| app.reload_routes! }

      config.app_middleware.use ::OmniAuth::Builder do
        next if GDS::SSO::Config.api_only?
        provider :gds, GDS::SSO::Config.oauth_id, GDS::SSO::Config.oauth_secret,
          client_options: {
            site: GDS::SSO::Config.oauth_root_url,
            authorize_url: "#{GDS::SSO::Config.oauth_root_url}/oauth/authorize",
            token_url: "#{GDS::SSO::Config.oauth_root_url}/oauth/access_token",
          }
      end

      def self.default_strategies
        Config.use_mock_strategies? ? [:mock_gds_sso, :gds_bearer_token] : [:gds_sso, :gds_bearer_token]
      end

      config.app_middleware.use Warden::Manager do |config|
        config.default_strategies *self.default_strategies
        config.failure_app = GDS::SSO::FailureApp
      end
    end
  end
end
