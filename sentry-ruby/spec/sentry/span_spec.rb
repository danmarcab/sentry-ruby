require "spec_helper"

RSpec.describe Sentry::Span do
  subject do
    described_class.new(
      op: "sql.query",
      description: "SELECT * FROM users;",
      status: "ok"
    )
  end

  describe "#get_trace_context" do
    it "returns correct context data" do
      context = subject.get_trace_context

      expect(context[:op]).to eq("sql.query")
      expect(context[:description]).to eq("SELECT * FROM users;")
      expect(context[:status]).to eq("ok")
      expect(context[:trace_id].length).to eq(32)
      expect(context[:span_id].length).to eq(16)
    end
  end

  describe "#to_hash" do
    before do
      subject.set_data("controller", "WelcomeController")
      subject.set_tag("foo", "bar")
    end

    it "returns correct data" do
      hash = subject.to_hash

      expect(hash[:op]).to eq("sql.query")
      expect(hash[:description]).to eq("SELECT * FROM users;")
      expect(hash[:status]).to eq("ok")
      expect(hash[:data]).to eq({ "controller" => "WelcomeController" })
      expect(hash[:tags]).to eq({ "foo" => "bar" })
      expect(hash[:trace_id].length).to eq(32)
      expect(hash[:span_id].length).to eq(16)
    end
  end

  describe "#set_status" do
    it "sets status" do
      subject.set_status("ok")

      expect(subject.status).to eq("ok")
    end
  end

  describe "#set_data" do
    it "sets data" do
      subject.set_data(:foo, "bar")

      expect(subject.data).to eq({ foo: "bar" })
    end
  end

  describe "#set_tag" do
    it "sets tag" do
      subject.set_tag(:foo, "bar")

      expect(subject.tags).to eq({ foo: "bar" })
    end
  end
end
