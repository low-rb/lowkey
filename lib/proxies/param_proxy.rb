# frozen_string_literal: true

require_relative '../interfaces/proxy'

module Lowkey
  class ParamProxy < Proxy
    attr_reader :type, :position, :value
    attr_accessor :expression

    def initialize(name:, source:, type:, position: nil, value: :LOWKEY_UNDEFINED, expression: nil) # rubocop:disable Metrics/ParameterLists
      super(name:, source:)

      @type = type
      @position = position
      @value = value

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

    def resolved_default
      if @expression
        return nil if @expression.default_value == :LOWTYPE_UNDEFINED
        return nil if @expression.default_value.nil? && required?

        value = @expression.default_value
        return value.value.inspect if value.class.name == 'ValueExpression'

        return value.inspect
      end

      return nil if @value == :LOWKEY_UNDEFINED

      @value
    end
  end
end
