module Sentry
  module Rack
    class Tracing
      def initialize(app)
        @app = app
      end

      def call(env)
        Sentry.clone_hub_to_current_thread unless Sentry.get_current_hub
        Sentry.with_scope do |scope|
          span = Sentry.start_span
          scope.set_span(span)

          begin
            response = @app.call(env)
          rescue => e
            finish_span(span, 500)

            raise e
          end

          finish_span(span, response[0])
          response
        end
      end

      def finish_span(span, status_code)
        span.set_http_status(status_code)
        span.finish
      end
    end
  end
end
