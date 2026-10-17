# frozen_string_literal: true

require_relative '../queries/query'

module Lowkey
  class MethodCallVisitor
    include Query

    def initialize(file_proxy:, parent_map:)
      @file_proxy = file_proxy
      @parent_map = parent_map
    end

    def visit(node)
      namespace = namespace(node:, parent_map:) || return
      module_proxy = file_proxy[namespace]

      module_proxy.add_method_call(node:)
      upsert_dependency(node:, namespace:)

      return unless node.name == :private && node.respond_to?(:start_line) && module_proxy.start_line && module_proxy.end_line
      return unless node.start_line > module_proxy.start_line && node.start_line < module_proxy.end_line

      module_proxy.private_start_line = node.start_line
    end

    private

    def upsert_dependency(node:, namespace:)
      return unless %i[include extend].include?(node.name)

        dependency_name = node.arguments.arguments.first.name.to_s
        dependency_name = "#{namespace}::#{dependency_name}" unless dependency_name.start_with?('::')
        file_proxy.upsert_dependency(namespace: dependency_name)
    end

    attr_reader :file_proxy, :parent_map
  end
end
