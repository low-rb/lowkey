# frozen_string_literal: true

require_relative '../interfaces/proxy'
require_relative '../queries/query'

module Lowkey
  class ModuleProxy < Proxy
    include Query

    attr_reader :namespace, :method_call_nodes
    attr_accessor :private_start_line, :keyed_methods, :class_methods

    def initialize(node:, name:, namespace:, source:)
      super(name:, source:)

      @node = node
      @namespace = namespace

      @private_start_line = nil

      @keyed_methods = {}
      @class_methods = {}

      @method_call_nodes = []
      @method_calls = nil
    end

    # Method call proxies are lazy loaded and may not always be needed. Sinatra adapter accesses Prism's method call nodes directly.
    def method_calls
      @method_calls ||= @method_call_nodes.map { |call_node| ProxyFactory.method_call_proxy(call_node:, file_path:, lines:) }
    end

    def [](key)
      key.start_with?('.') ? query(node: @node, namespace: nil, name: key.delete_prefix('.')) : @keyed_methods[key]
    end

    class << self
      # "def self.method", "def ClassName.method" or a method within "class << self"/"class << ClassName".
      def class_method?(method_node:, parent_map:)
        return class_receiver?(receiver: method_node.receiver, node: method_node, parent_map:) if method_node.receiver
        return false unless (singleton_class_node = singleton_class_node(method_node:, parent_map:))

        class_receiver?(receiver: singleton_class_node.expression, node: singleton_class_node, parent_map:)
      end

      # A method defined on an object, like "def object.method" or a method within "class << object".
      def singleton_method?(method_node:, parent_map:)
        !method_node.receiver.nil? || !singleton_class_node(method_node:, parent_map:).nil?
      end

      # Any other receiver, like "def object.method", defines a method on that object rather than the class.
      def class_receiver?(receiver:, node:, parent_map:)
        receiver = unwrap(node: receiver)
        return true if receiver.is_a?(::Prism::SelfNode)
        return false unless receiver.is_a?(::Prism::ConstantReadNode) || receiver.is_a?(::Prism::ConstantPathNode)

        # The receiver can be the class name or any part of its namespace, like "Name" or "Namespace::Name".
        "::#{namespace(node:, parent_map:)}".end_with?("::#{receiver.full_name}")
      rescue ::Prism::ConstantPathNode::DynamicPartsInConstantPathError
        false
      end

      private

      def singleton_class_node(method_node:, parent_map:)
        node = parent_map[method_node]
        node = parent_map[node] until node.nil? || module_node?(node) || node.is_a?(::Prism::SingletonClassNode)

        node.is_a?(::Prism::SingletonClassNode) ? node : nil
      end

      # "def (Namespace::Name).method" wraps the receiver in parentheses.
      def unwrap(node:)
        return node unless node.is_a?(::Prism::ParenthesesNode)

        body = node.body
        body.is_a?(::Prism::StatementsNode) && body.body.one? ? body.body.first : body
      end

      def namespace(node:, parent_map:)
        names = []

        while (node = parent_map[node])
          names.unshift(node.constant_path.full_name) if module_node?(node)
        end

        names.join('::')
      end

      def module_node?(node)
        node.is_a?(::Prism::ClassNode) || node.is_a?(::Prism::ModuleNode)
      end
    end
  end
end
