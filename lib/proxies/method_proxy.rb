# frozen_string_literal: true

require_relative '../interfaces/proxy'
require_relative '../queries/query'

module Lowkey
  class MethodProxy < Proxy
    include Query

    attr_reader :params, :body, :return_proxy

    def initialize(name:, source:, param_proxies: [], body_proxy: nil, return_proxy: nil)
      super(name:, source:)

      @params = param_proxies
      @body = body_proxy
      @return_proxy = return_proxy

      @named_params = name_params
      @tagged_params = tag_params
    end

    def [](key)
      # TODO: Initialize method proxy with method node and support query code path.
      key.start_with?('.') ? query(node: @node, namespace: nil, name: key.delete_prefix('.')) : @named_params[key]
    end

    def tagged_params(tag)
      @tagged_params[tag] || []
    end

    def rewrite_signature
      old_line = lines[start_index]
      scope_prefix = old_line.match?(/def self\./) ? 'def self.' : 'def '
      all_params = @params.map { |p| p.expression ? p.export(typed: false) : p.name.to_s }
      return_suffix = @return_proxy ? " #{@return_proxy.export}" : ''
      indent = old_line[/^\s*/]
      lines[start_index] = "#{indent}#{scope_prefix}#{@name}(#{all_params.join(', ')})#{return_suffix}\n"
    end

    def expressions?
      @params.any?(&:expression) || @return_proxy
    end

    # Lazily memoized rather than computed in #initialize -- param_proxy.expression isn't
    # populated yet at construction time (Lowkey.load builds these while parsing; the
    # Evaluator only sets each param's #expression afterward, once the class body has
    # finished loading), so computing this eagerly at construction would permanently bake
    # in an empty result. Lowkey.make_shareable! warms this explicitly (calls it once for
    # every method proxy in the registry) before freezing, since a lazy `||=` write would
    # otherwise raise FrozenError the first time something calls this after the freeze.
    def params_with_expressions
      @params_with_expressions ||= @params.filter(&:expression)
    end

    private

    def name_params
      @params.each_with_object({}) do |param, named_params|
        named_params[param.name] = param if %i[pos_req pos_opt key_req key_opt].include?(param.type)
      end
    end

    def tag_params
      tags = { required: [], optional: [], positional: [], keyword: [], value: [] }

      tag_from_types = {
        required: %i[pos_req key_req],
        optional: %i[pos_opt key_opt],
        positional: %i[pos_req pos_opt],
        keyword: %i[key_req key_opt]
      }

      tag_from_types.each do |tag, types|
        @params.each do |param|
          tags[tag] << param if types.include?(param.type)
          tags[:value] << param if param.value != :LOWKEY_UNDEFINED
        end
      end

      tags
    end
  end
end
