# frozen_string_literal: true

module Lowkey
  # Reads Ruby values like nil, true, 'text', 3, -1.5 or :symbol from Prism nodes or text, without evaluating any code.
  # Ignores potentially malicious values like variables, method calls or interpolated strings.
  module ValueParser
    KEYWORDS = { 'nil' => nil, 'true' => true, 'false' => false }.freeze
    VALUE_KEYWORDS = KEYWORDS.keys.freeze
    VALUE_STARTS = ["'", '"', ':', '-', *'0'..'9'].freeze

    NUMBER = /\A-?\d/
    FLOAT = /\A-?(?:0|[1-9][\d_]*)(?:\.\d[\d_]*)?(?:[eE][-+]?\d+)?\z/
    SINGLE_QUOTED = /\A'((?:[^'\\]|\\.)*)'\z/m
    DOUBLE_QUOTED = /\A"((?:[^"\\]|\\.)*)"\z/m
    # #{}, #@ and #$ interpolate, unless escaped.
    INTERPOLATION = /(?<!\\)(?:\\\\)*\#[{@$]/
    # A double-quoted string's escapes: Unicode, hex, octal, then a character.
    ESCAPE = /\\(u\{[\h ]+\}|u\h{4}|x\h{1,2}|[0-7]{1,3}|.)/m
    ESCAPES = { 'n' => "\n", 't' => "\t", 'r' => "\r", 's' => ' ', 'e' => "\e", 'a' => "\a", 'b' => "\b", 'f' => "\f",
                'v' => "\v", "\n" => '' }.freeze
    SYMBOL = %r{\A:([A-Za-z_]\w*[?!=]?|\[\]=?|\*\*|[-+]@|<=>|===?|=~|![=~]?|<[<=]?|>[>=]?|[-+*/%&|^~])\z}

    module_function

    # Returns the value, or yields a block when the input isn't a value. It's read as Ruby reads it, without Prism,
    # which only parses files, so reading a value never loads it.
    def parse(input)
      return yield(input) unless possible_value?(input)

      text = input.strip
      return KEYWORDS[text] if KEYWORDS.key?(text)

      found = literal(text)
      return yield(input) if found.empty?

      found.first
    end

    # The literal's value in an array, or an empty one when it isn't one: a number, a string or a symbol.
    def literal(text)
      return number(text) if text.match?(NUMBER)
      return [single_quoted(text)].compact if text.start_with?("'")
      return [double_quoted(text)].compact if text.start_with?('"')

      symbol(text)
    end

    # Integers as Ruby writes them, like 1_000, 0x1F or 007, then floats, like 1.5e-3.
    def number(text)
      [Integer(text)]
    rescue ArgumentError
      float(text)
    end

    def float(text)
      return [] unless text.match?(FLOAT)

      [Float(text)]
    rescue ArgumentError
      []
    end

    # Only \\ and \' are escapes in single quotes.
    def single_quoted(text)
      text[SINGLE_QUOTED, 1]&.gsub(/\\([\\'])/, '\1')
    end

    # With its escapes, like \t, \u00e9 or \101, and nil for an interpolation, or a control escape, like \C-a.
    def double_quoted(text)
      body = text[DOUBLE_QUOTED, 1]
      return if body.nil? || body.match?(INTERPOLATION) || body.match?(/\\[cCM]/)

      body.gsub(ESCAPE) { escaped(Regexp.last_match(1)) }
    end

    def escaped(escape)
      return unicode(escape[1..]) if escape.match?(/\Au./)
      return escape[1..].hex.chr if escape.match?(/\Ax./)
      return escape.oct.chr if escape.match?(/\A[0-7]/)

      ESCAPES.fetch(escape, escape)
    end

    # Like 00e9, or {1F600 1F601}, as UTF-8.
    def unicode(codes)
      codes.delete('{}').split.map { it.hex.chr(Encoding::UTF_8) }.join
    end

    def symbol(text)
      return [text[SYMBOL, 1].to_sym] if text.match?(SYMBOL)

      quoted = double_quoted(text.delete_prefix(':')) if text.start_with?(':"')
      return [quoted.to_sym] if quoted

      []
    end

    # Prism's reading of the text, which parse reads as, for checking it against.
    def prism_parse(input)
      Lowkey.load_prism
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
      value_nodes.include?(node.class)
    end

    # Prism's value nodes, once Prism has loaded.
    def value_nodes
      @value_nodes ||= [
        Prism::NilNode,
        Prism::TrueNode,
        Prism::FalseNode,
        Prism::IntegerNode,
        Prism::FloatNode,
        Prism::StringNode,
        Prism::SymbolNode
      ].freeze
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
