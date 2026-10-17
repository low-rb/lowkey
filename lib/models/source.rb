# frozen_string_literal: true

module Lowkey
  class WriteError < StandardError; end

  class Source
    attr_reader :file_path, :scope, :lines, :start_offset, :end_offset, :start_column, :end_column
    attr_accessor :start_line, :end_line

    # Offsets are byte offsets of the node in the original file. Columns are byte columns.
    def initialize(file_path:, scope:, lines:, start_line:, end_line: nil, location: nil) # rubocop:disable Metrics/ParameterLists
      @file_path = file_path
      @scope = scope

      @start_line = start_line
      @end_line = end_line
      @lines = lines

      @start_offset = location&.start_offset
      @end_offset = location&.end_offset
      @start_column = location&.start_column
      @end_column = location&.end_column
    end

    def lines=(new_lines)
      raise WriteError, "More new lines than old lines, won't fit" if new_lines.count > lines.count

      indent = lines[start_index][/^\s+/]

      [start_index..end_index].each do |line_index|
        lines[line_index] = indent + new_lines.pop.to_s || ''
      end
    end

    def wrap(prefix:, suffix:)
      start_line = lines[start_index]
      indent = start_line[/^\s+/]

      lines[start_index] = indent + prefix.to_s + start_line.lstrip
      lines[end_index] = lines[end_index] + suffix.to_s
    end

    def export
      lines[start_index..end_index].join
    end

    # Applies edits of [start_offset, end_offset, text] to a range of lines, keeping the amount of lines the same so that
    # other sources sharing the lines stay valid. Offsets are byte offsets from the start of the range's first line.
    def rewrite_lines(range:, edits:)
      new_lines = apply_edits(text: lines[range].join.b, edits:).force_encoding(encoding).lines
      raise WriteError, "More new lines than old lines, won't fit" if new_lines.count > range.count

      lines[range] = new_lines + Array.new(range.count - new_lines.count, '')
    end

    def encoding
      lines.first&.encoding || Encoding::UTF_8
    end

    # Edits are applied from last to first so that their offsets stay valid.
    def apply_edits(text:, edits:)
      edits.sort_by { |start_offset, _end_offset, _text| -start_offset }.reduce(text) do |new_text, (start_offset, end_offset, edit)|
        new_text.byteslice(0, start_offset) + edit.b + new_text.byteslice(end_offset..)
      end
    end

    def start_index
      start_line - 1
    end

    def end_index
      end_line - 1
    end

    # The byte offset of the start of the first line.
    def line_offset
      start_offset - start_column
    end
  end
end
