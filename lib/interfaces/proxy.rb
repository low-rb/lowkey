# frozen_string_literal: true

module Lowkey
  # Proxy and Source abstract away nodes and avoid referencing the node on the proxy itself. Will this change?
  # The goal is to make an API that's indiependent of the AST, that can manipulate source code line by line.
  #
  # Methods delegate to the source by hand, as Forwardable allocates an array of arguments on every call.
  # Subclasses can build their source on first access by overriding "source".
  class Proxy
    attr_reader :name, :source

    def initialize(name:, source:)
      @name = name
      @source = source
    end

    def file_path = source.file_path
    def scope = source.scope

    def lines = source.lines

    def lines=(new_lines)
      source.lines = new_lines
    end

    def start_line = source.start_line
    def end_line = source.end_line
    def start_index = source.start_index
    def end_index = source.end_index

    def start_offset = source.start_offset
    def end_offset = source.end_offset
    def start_column = source.start_column
    def end_column = source.end_column
    def line_offset = source.line_offset

    def wrap(prefix:, suffix:) = source.wrap(prefix:, suffix:)
    def export = source.export
  end
end
