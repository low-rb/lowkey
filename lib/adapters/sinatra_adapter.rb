# frozen_string_literal: true

require_relative '../factories/source_factory'
require_relative '../interfaces/adapter'

module Lowkey
  class SinatraAdapter < Adapter
    def initialize(file_proxy:, class_proxy:)
      @file_proxy = file_proxy
      @class_proxy = class_proxy
    end

    def load # rubocop:disable Metrics/AbcSize
      # Type check return values.
      @class_proxy.method_calls.each do |method_call|
        next unless %i[get post patch put delete options].include?(method_call.name)

        method_call_node = method_call.node

        arguments_node = method_call_node.compact_child_nodes.first
        next unless arguments_node.is_a?(Prism::ArgumentsNode)

        pattern = arguments_node.arguments.first.content
        route = "#{method_call_node.name.upcase} #{pattern}"
        name = route
        source = SourceFactory.method_call_source(method_call_node:, arguments_node:, file_path:, lines:)

        next unless (return_proxy = ProxyFactory.return_proxy(method_node: method_call_node, name:, file_path:, lines:))

        param_proxies = [ParamProxy.new(source:, name:, type: :pos_req, position: 0)]
        method_proxy = MethodProxy.new(source:, name:, param_proxies:, return_proxy:)

        @class_proxy.keyed_methods[route] = method_proxy
      end
    end

    private

    def file_path
      @file_proxy.file_path
    end

    def lines
      @file_proxy.lines
    end
  end
end
