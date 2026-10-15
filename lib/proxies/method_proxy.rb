# frozen_string_literal: true

require_relative '../interfaces/proxy'
require_relative '../queries/query'

module Lowkey
  class MethodProxy < Proxy
    include Query

    attr_reader :params, :body, :return_proxy, :signature_end_line, :receiver

    # @param receiver - The source of the receiver in "def receiver.method", such as "self".
    def initialize(name:, source:, param_proxies: [], body_proxy: nil, return_proxy: nil, signature_end_line: nil, receiver: nil) # rubocop:disable Metrics/ParameterLists
      super(name:, source:)

      @receiver = receiver
      @params = param_proxies
      @body = body_proxy
      @return_proxy = return_proxy
      @signature_end_line = signature_end_line || source.start_line
      @rewritten = false

      @named_params = name_params
      @tagged_params = tag_params
    end

    def [](key)
      # TODO: Initialize method proxy with method node and support query code path.
      key.start_with?('.') ? query(node: @node, namespace: nil, name: key.delete_prefix('.')) : @named_params[key]
    end

    def tagged_params(tag)
      @tagged_params[tag] || []
    end

    # Removes types from the signature, leaving the rest of the source as is. The amount of lines stays the same.
    def rewrite_signature
      return if @rewritten

      signature_range = start_index..(signature_end_line - 1)

      edits = param_edits
      edits << return_type_edit(signature: lines[signature_range].join.b) if @return_proxy&.expression

      @source.rewrite_lines(range: signature_range, edits:)
      @rewritten = true
    end

    # Whether the method is defined on its receiver, such as "def self.method", rather than on the current class.
    def receiver?
      !@receiver.nil?
    end

    def expressions?
      @params.any?(&:expression) || !@return_proxy&.expression.nil?
    end

    def params_with_expressions
      @params_with_expressions ||= @params.filter(&:expression)
    end

    private

    def param_edits
      params_with_expressions.map do |param|
        [param.start_offset - line_offset, param.end_offset - line_offset, param.export(typed: false)]
      end
    end

    # Also removes the whitespace before the return type, or the whole line when the return type is on its own line.
    def return_type_edit(signature:)
      start_offset = @return_proxy.start_offset - line_offset
      end_offset = @return_proxy.end_offset - line_offset
      line_start_offset = start_offset - @return_proxy.start_column
      before = signature.byteslice(line_start_offset, @return_proxy.start_column)

      return [line_start_offset, end_offset + 1, ''] if before.strip.empty? && signature.byteslice(end_offset) == "\n"

      [start_offset - before[/[ \t]*\z/].bytesize, end_offset, '']
    end

    def name_params
      @params.each_with_object({}) do |param, named_params|
        named_params[param.name] = param if %i[pos_req pos_opt key_req key_opt].include?(param.type)
      end
    end

    def tag_params
      tags = { required: [], optional: [], positional: [], keyword: [], value: [] }

      tag_from_types = {
        required: %i[pos_req key_req],
        optional: %i[pos_opt key_opt],
        positional: %i[pos_req pos_opt],
        keyword: %i[key_req key_opt]
      }

      tag_from_types.each do |tag, types|
        @params.each do |param|
          tags[tag] << param if types.include?(param.type)
          tags[:value] << param if param.value != :LOWKEY_UNDEFINED
        end
      end

      tags
    end
  end
end
