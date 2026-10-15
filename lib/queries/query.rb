# frozen_string_literal: true

require 'prism'

module Lowkey
  module Query
    # TODO: Make name a keypath.
    def query(node:, namespace:, name:) # rubocop:disable Lint/UnusedMethodArgument
      node.breadth_first_search do |n|
        n.respond_to?(:name) && n.name == name.to_sym
      end
    end

    def namespace(node:, parent_map:)
      path = namespace_path(node:, parent_map:)
      return nil if path.nil?

      path.empty? ? 'Object' : path
    end

    private

    # Each node caches the namespace above it, so our first ancestor will have the full namespace.
    def namespace_path(node:, parent_map:)
      namespaces = parent_map.namespaces
      return namespaces[node] if namespaces.key?(node)

      namespaces[node] = resolve_namespace_path(node:, parent_map:)
    end

    def resolve_namespace_path(node:, parent_map:)
      # When inside RBX, Prism thinks we're defining a class because of "<".
      return nil if node.respond_to?(:constant_path) && node.constant_path.is_a?(Prism::MissingNode)
      return '' if (parent = parent_map[node]).nil?

      path = namespace_path(node: parent, parent_map:)
      return path if path.nil? || !node.respond_to?(:constant_path)

      name = node.constant_path.name.to_s
      (path.empty? ? name : "#{path}::#{name}").freeze
    end
  end
end
