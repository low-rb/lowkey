# frozen_string_literal: true

require 'json'

module Lowkey
  class MethodCalls
    include Comparable

    attribute name: String, age: Integer
    attr_reader :name, :age

    def value = type(String | 'café') + type(Integer | value(Integer)).to_s
  end
end
