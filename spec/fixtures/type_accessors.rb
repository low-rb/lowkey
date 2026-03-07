# frozen_string_literal: true

require_relative 'mock_lowtype'

class TypeAccessors
  include Lowkey::LowType

  type_reader one: String
  type_writer two: String
  type_accessor three: String

  def initialize
    @one = 1
    @two = 2
    @three = 3
  end
end
