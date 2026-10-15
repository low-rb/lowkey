# frozen_string_literal: true

require_relative '../interfaces/proxy'

module Lowkey
  class ParamProxy < Proxy
    attr_reader :type, :position, :value
    attr_accessor :default, :expression

    # @param value - The source of the param's value, such as "String | 'default'".
    # @param default - The source of the default value within the value, such as "'default'". Can be overridden.
    def initialize(name:, source:, type:, position: nil, value: :LOWKEY_UNDEFINED, default: nil, expression: nil) # rubocop:disable Metrics/ParameterLists
      super(name:, source:)

      @type = type
      @position = position
      @value = value
      @default = default

      @expression = expression
    end

    def required?
      @value == :LOWKEY_UNDEFINED
    end

    def export(typed: true)
      return @source.export if typed
      return untyped_keyword_param if %i[key_req key_opt].include?(@type)

      untyped_positional_param
    end

    private

    def untyped_keyword_param
      default = resolved_default
      default.nil? ? "#{@name}:" : "#{@name}: #{default}"
    end

    def untyped_positional_param
      default = resolved_default
      default.nil? ? @name.to_s : "#{@name} = #{default}"
    end

    # Uses the source of the default value rather than the evaluated default value, to preserve the developer's code.
    def resolved_default
      if @expression
        return nil if @expression.required?

        return @default
      end

      return nil if @value == :LOWKEY_UNDEFINED

      @value
    end
  end
end
