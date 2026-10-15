# frozen_string_literal: true

module Lowkey
  class ParentMap
    # The namespace of each node, cached by Query#namespace.
    attr_reader :namespaces

    def initialize(root_node:)
      @parent_map = {}
      @namespaces = {}
      @current_parent = nil

      map(root_node)
    end

    def [](node)
      @parent_map[node]
    end

    private

    def map(node)
      @parent_map[node] = @current_parent

      old_parent = @current_parent
      @current_parent = node

      node.compact_child_nodes.each do |n|
        map(n)
      end

      @current_parent = old_parent
    end
  end
end
