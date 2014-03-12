module Napa
  class Middleware
    class Authentication
      class ExcludedPaths
        def initialize(app)
          @app            = app
          @excluded_paths = [%r{\A/github_webhooks/[0-9]+\z}]
        end

        def call(env)
          if env['REQUEST_PATH'].match(Regexp.union(@excluded_paths))
            @app.call(env)
          else
            Napa::Middleware::Authentication.new(@app).call(env)
          end
        end
      end
    end
  end
end
