require "sentry-ruby"
require "sentry/rails/configuration"
require "sentry/rails/railtie"

module Sentry
  module Rails
    META = { "name" => "sentry.ruby.rails", "version" => Sentry::Rails::VERSION }.freeze

    def self.subscribe_tracing_events
      # need to avoid duplicated subscription
      return if @subscribed

      ActiveSupport::Notifications.subscribe('sql.active_record') do |event|
        data = event.payload

        if !["SCHEMA", "TRANSACTION"].include? data[:name]
          timestamp = Time.now.utc.to_f
          start_timestamp = timestamp - event.duration.round(1)

          new_span = Sentry.start_span(op: event.name, description: data[:sql], start_timestamp: start_timestamp, timestamp: timestamp)
          new_span.set_data(:name, data[:name])
          new_span.set_data(:connection_id, data[:connection_id])
        end
      end

      @subscribed = true
    end
  end

  def self.sdk_meta
    Sentry::Rails::META
  end
end
