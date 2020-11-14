require "spec_helper"

RSpec.describe Sentry::Rails, type: :request do
  before(:all) do
    make_basic_app
  end

  let(:transport) do
    Sentry.get_current_client.transport
  end

  let(:event) do
    transport.events.last.to_json_compatible
  end

  after do
    transport.events = []
  end

  it "records spans" do
    get "/posts"

    expect(transport.events.count).to eq(1)
    event = transport.events.last.to_hash

    expect(event[:spans].count).to eq(2)

    first_span = event[:spans][0]
    expect(first_span[:op]).to eq("/posts")
    expect(first_span[:status]).to eq("internal_error")
    expect(first_span[:data]).to eq({ "status_code" => 500 })

    second_span = event[:spans][1]
    expect(second_span[:op]).to eq("sql.active_record")
    expect(second_span[:description]).to eq("SELECT \"posts\".* FROM \"posts\"")
    expect(second_span[:parent_span_id]).to eq(first_span[:span_id])
  end
end
