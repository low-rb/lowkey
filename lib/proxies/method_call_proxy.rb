# frozen_string_literal: true

require_relative '../factories/source_factory'
require_relative '../interfaces/proxy'

module Lowkey
  # A method call like "include Module", "attr_reader :name" or "type(String | 'default')".
  # Details, including the source, are read from the node on first access as consumers often only need a few method calls.
  class MethodCallProxy < Proxy
    attr_reader :node

    def initialize(name:, node:, file_path:, lines:)
      super(name:, source: nil)

      @node = node
      @file_path = file_path
      @lines = lines
      @rewritten = false
    end

    def source
      @source ||= SourceFactory.call_source(call_node: @node, file_path: @file_path, lines: @lines)
    end

    # The source of the receiver in "receiver.method", such as "self".
    def receiver
      return @receiver if defined?(@receiver)

      @receiver = @node.receiver&.slice
    end

    def receiver?
      !receiver.nil?
    end

    # The source of each argument.
    def arguments
      @arguments ||= argument_nodes.map(&:slice)
    end

    # The keys of a hash argument like "method key: value" when every key is a symbol, otherwise nil.
    def keywords
      return @keywords if defined?(@keywords)

      hash = argument_nodes.last
      symbol_keys = (hash.is_a?(Prism::KeywordHashNode) || hash.is_a?(Prism::HashNode)) &&
                    hash.elements.all? { |element| element.is_a?(Prism::AssocNode) && element.key.is_a?(Prism::SymbolNode) }

      @keywords = symbol_keys ? hash.elements.map { |element| element.key.unescaped.to_sym } : nil
    end

    # The source of the default value when the argument is "Type | 'default'".
    def default
      return @default if defined?(@default)

      union = argument_nodes.one? && ProxyFactory.union?(node: argument_nodes.first)
      @default = union ? ProxyFactory.default_source(node: argument_nodes.first) : nil
    end

    # Replaces the method call with text, once. Calls on the same line must be rewritten from last to first.
    def rewrite(text)
      return if @rewritten

      source.rewrite_lines(range: start_index..end_index, edits: [[start_offset - line_offset, end_offset - line_offset, text]])
      @rewritten = true
    end

    # Removes the method call, along with its lines when it's the only code on them, and any blank line left orphaned.
    def remove
      return if @rewritten
      return rewrite('') unless own_lines?

      (start_index..end_index).each { |index| lines[index] = '' }
      remove_orphaned_blank_line
      @rewritten = true
    end

    private

    def argument_nodes
      @node.arguments&.arguments || []
    end

    def own_lines?
      lines[start_index].b.byteslice(0, start_column).strip.empty? && lines[end_index].b.byteslice(end_column..).strip.empty?
    end

    # A blank line after a removed line is orphaned when it follows another blank line or opens a class/module.
    def remove_orphaned_blank_line
      next_index = ((end_index + 1)...lines.count).find { |index| lines[index] != '' }
      return unless next_index && lines[next_index].strip.empty?

      lines[next_index] = '' if orphaning_line?(line: previous_line(index: start_index))
    end

    def orphaning_line?(line:)
      line.nil? || line.strip.empty? || line.match?(/\A\s*(?:class|module)\b/)
    end

    # Skips removed lines, which are empty strings rather than blank lines.
    def previous_line(index:)
      previous_index = (0...index).reverse_each.find { |line_index| lines[line_index] != '' }
      previous_index ? lines[previous_index] : nil
    end
  end
end
