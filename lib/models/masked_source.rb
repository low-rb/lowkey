# frozen_string_literal: true

module Lowkey
  # A file's source with the bodies of methods Prism couldn't parse, like an RBX file's templates, blanked out with
  # spaces, so Prism parses the rest of the file. Each byte becomes a space and newlines stay, so lines, columns and
  # offsets still point at the file itself.
  class MaskedSource
    DEF_PATTERN = /\A(\s*)def\b/

    def initialize(source:, error_lines:)
      @lines = source.lines
      @error_lines = error_lines
    end

    def to_s
      unparsed_bodies.each do |body|
        body.each { |index| @lines[index] = @lines[index].b.gsub(/[^\n]/n, ' ') }
      end

      @lines.join
    end

    private

    # The line ranges of the bodies of methods with an error in them.
    def unparsed_bodies
      # An error at the end of the file, like a missing "end", is on the line after its last.
      @error_lines.filter_map { |line| body_around([line, @lines.count].min - 1) }.uniq
    end

    # The body of the method an error's in: from the line after its "def" to the line before its lined up "end".
    def body_around(error_index)
      def_index = error_index.downto(0).find { |index| @lines[index].match?(DEF_PATTERN) }
      return unless def_index

      indent = @lines[def_index][DEF_PATTERN, 1]
      end_index = ((def_index + 1)...@lines.count).find { |index| @lines[index].match?(/\A#{indent}end\b/) }
      return unless end_index && error_index.between?(def_index, end_index)

      (def_index + 1)...end_index
    end
  end
end
