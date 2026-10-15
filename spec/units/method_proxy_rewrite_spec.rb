# frozen_string_literal: true

require 'prism'
require_relative '../../lib/lowkey'

RSpec.describe Lowkey::MethodProxy do
  subject(:file_proxy) { Lowkey.load('spec/fixtures/typed_methods.rb', cache: false) }

  let(:class_proxy) { file_proxy['Lowkey::TypedMethods'] }
  let(:required) { double('expression', required?: true) }
  let(:optional) { double('expression', required?: false) }
  let(:return_type) { double('expression') }

  # Simulates LowType evaluating the expressions of typed params and return types.
  def type(method_proxy, **expressions)
    expressions.each { |name, expression| method_proxy.params.find { |param| param.name == name }.expression = expression }
    method_proxy.return_proxy.expression = return_type if method_proxy.return_proxy
    method_proxy.rewrite_signature
    method_proxy.export
  end

  describe '#rewrite_signature' do
    it 'removes types and keeps untyped params, splats and blocks' do
      method_proxy = class_proxy[:one_line]

      expect(type(method_proxy, two: optional, three: required)).to eq(<<-RUBY)
    def one_line(one, two = 'café', *rest, three:, four: 'untyped', **opts, &block) # rubocop:disable Metrics/ParameterLists
      [one, two, rest, three, four, opts, block]
    end
      RUBY
    end

    it 'rewrites multiline signatures without changing the amount of lines' do
      method_proxy = class_proxy[:multiline]
      line_count = file_proxy.lines.count

      expect(type(method_proxy, one: required, two: optional)).to eq(<<-RUBY)
    def multiline(
      one,
      two: 2
    )
      one + two
    end
      RUBY
      expect(file_proxy.lines.count).to eq(line_count)
    end

    it 'removes a return type on its own line' do
      expect(type(class_proxy[:own_line_return_type], one: required)).to eq(<<-RUBY)
    def own_line_return_type(one)
      one
    end
      RUBY
    end

    it 'unwraps value expressions and keeps endless method bodies' do
      expect(type(class_proxy[:value_default], one: optional)).to eq("    def value_default(one = String) = one\n")
    end

    it 'keeps code before and after the signature' do
      expect(type(class_proxy[:with_prefix], one: required)).to start_with('    private def with_prefix(one) = one # rubocop')
    end

    it 'rewrites class methods' do
      expect(type(class_proxy[:class_method], one: optional)).to eq("    def self.class_method(one: nil) = one\n")
    end

    it 'only rewrites once' do
      method_proxy = class_proxy[:own_line_return_type]
      type(method_proxy, one: required)

      expect { method_proxy.rewrite_signature }.not_to(change { method_proxy.export })
    end

    it 'is reflected in file_proxy.export since lines are shared' do
      type(class_proxy[:own_line_return_type], one: required)
      expect(file_proxy.export).to include("def own_line_return_type(one)\n      one\n")
    end
  end
end
