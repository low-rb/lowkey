# frozen_string_literal: true

require 'prism'

module Lowkey
  # Reads Ruby values like nil, true, 'text', 3, -1.5 or :symbol from Prism nodes or text, without evaluating any code.
  # Ignores potentially malicious values like variables, method calls or interpolated strings.
  module ValueParser
    VALUE_NODES = [
      Prism::NilNode,
      Prism::TrueNode,
      Prism::FalseNode,
      Prism::IntegerNode,
      Prism::FloatNode,
      Prism::StringNode,
      Prism::SymbolNode
    ].freeze

    VALUE_KEYWORDS = %w[nil true false].freeze
    VALUE_STARTS = ["'", '"', ':', '-', *'0'..'9'].freeze

    module_function

    # Returns the AST node's value or yields a block.
    def parse(input)
      return yield(input) unless possible_value?(input)

      result = Prism.parse(input)
      statements = result.value.statements.body
      return yield(input) unless result.errors.empty? && statements.one? && value?(statements.first)

      value(statements.first)
    end

    def possible_value?(input)
      text = input.strip
      VALUE_KEYWORDS.include?(text) || text.start_with?(*VALUE_STARTS)
    end

    def value?(node)
      VALUE_NODES.include?(node.class)
    end

    # Returns the AST node's value or yields a block.
    def value(node)
      case node
      when Prism::NilNode then nil
      when Prism::TrueNode then true
      when Prism::FalseNode then false
      when Prism::StringNode then node.unescaped
      when Prism::SymbolNode then node.unescaped.to_sym
      when Prism::IntegerNode, Prism::FloatNode then node.value
      else yield
      end
    end
  end
end
