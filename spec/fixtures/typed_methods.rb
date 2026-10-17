# frozen_string_literal: true

module Lowkey
  class TypedMethods
    def one_line(one, two = String | 'café', *rest, three: Integer, four: 'untyped', **opts, &block) -> { String } # rubocop:disable Metrics/ParameterLists
      [one, two, rest, three, four, opts, block]
    end

    def multiline(
      one = String,
      two: Integer | 2
    ) -> { Integer }
      one + two
    end

    def own_line_return_type(one = String)
      -> { String }
      one
    end

    def value_default(one = String | value(String)) = one

    private def with_prefix(one = String) = one # rubocop:disable Style/AccessModifierDeclarations

    def self.class_method(one: String | nil) = one
  end
end
