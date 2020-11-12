require 'spec_helper'

RSpec.describe Sentry::Rack::Tracing do
  let(:exception) { ZeroDivisionError.new("divided by 0") }
  let(:additional_headers) { {} }
  let(:env) { Rack::MockRequest.env_for("/test", additional_headers) }

  before do
    Sentry.init do |config|
      config.breadcrumbs_logger = [:sentry_logger]
      config.dsn = DUMMY_DSN
      config.transport.transport_class = Sentry::DummyTransport
    end
  end

  let(:transport) do
    Sentry.get_current_client.transport
  end

  it "starts a span and finishes it" do
    app = ->(_) do
      Sentry.capture_message("foo")
      [200, {}, ["ok"]]
    end

    stack = described_class.new(app)

    stack.call(env)

    event = transport.events.last
    span = event.spans.first
    expect(span.status).to eq("ok")
    expect(span.data).to eq({ "status_code" => 200 })
    expect(span.timestamp).not_to be_nil
  end

  context "when there's an exception" do
    it "still finishes the span" do
      app = ->(_) do
        Sentry.capture_message("foo")
        raise "foo"
      end

      stack = described_class.new(app)

      stack.call(env) rescue nil

      event = transport.events.last
      span = event.spans.first
      expect(span.status).to eq("internal_error")
      expect(span.data).to eq({ "status_code" => 500 })
      expect(span.timestamp).not_to be_nil
    end
  end
end

