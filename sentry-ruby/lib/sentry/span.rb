# frozen_string_literal: true
require "securerandom"

module Sentry
  class Span
    attr_reader :trace_id, :span_id, :parent_span_id, :start_timestamp, :timestamp, :description, :op, :status, :tags, :data
    attr_accessor :span_recorder

    def initialize(description: nil, op: nil, status: nil, trace_id: nil, parent_span_id: nil, start_timestamp: nil, timestamp: nil)
      @trace_id = trace_id || SecureRandom.uuid.delete("-")
      @span_id = SecureRandom.hex(8)
      @parent_span_id = parent_span_id
      @start_timestamp = start_timestamp || Time.now.utc.iso8601
      @timestamp = timestamp
      @description = description
      @op = op
      @status = status
      @data = {}
      @tags = {}
      @span_recorder = SpanRecorder.new(1000)
    end

    def finish
      # already finished
      return if @timestamp

      @timestamp = Time.now.utc.iso8601
    end

    def to_hash
      {
        trace_id: @trace_id,
        span_id: @span_id,
        parent_span_id: @parent_span_id,
        start_timestamp: @start_timestamp,
        timestamp: @timestamp,
        description: @description,
        op: @op,
        status: @status,
        tags: @tags,
        data: @data
      }
    end

    def get_trace_context
      {
        trace_id: @trace_id,
        span_id: @span_id,
        description: @description,
        op: @op,
        status: @status
      }
    end

    def start_child(**options)
      options = options.dup.merge(trace_id: @trace_id, parent_span_id: @span_id)
      child_span = self.class.new(options)
      child_span.span_recorder = @span_recorder
      @span_recorder.add(child_span)
      child_span
    end

    def set_op(op)
      @op = op
    end

    def set_status(status)
      @status = status
    end

    def set_http_status(status_code)
      set_data("status_code", status_code)

      status =
        if status_code >= 200 && status_code < 299
          "ok"
        else
          case status_code
          when 400
            "invalid_argument"
          when 401
            "unauthenticated"
          when 403
            "permission_denied"
          when 404
            "not_found"
          when 409
            "already_exists"
          when 429
            "resource_exhausted"
          when 499
            "cancelled"
          when 500
            "internal_error"
          when 501
            "unimplemented"
          when 503
            "unavailable"
          when 504
            "deadline_exceeded"
          end
        end
      set_status(status)
    end

    def set_data(key, value)
      @data[key] = value
    end

    def set_tag(key, value)
      @tags[key] = value
    end

    class SpanRecorder
      attr_reader :max_length, :spans

      def initialize(max_length)
        @max_length = max_length
        @spans = []
      end

      def add(span)
        if @spans.count < @max_length
          @spans << span
        end
      end
    end
  end
end
