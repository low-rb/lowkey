# frozen_string_literal: true

require 'prism'
require_relative '../../lib/lowkey'

class MockCallNode
  attr_reader :name

  def initialize(name)
    @name = name
  end
end

RSpec.describe Lowkey::ClassProxy do
  subject(:class_proxy) { described_class.new(node:, name: 'MockClass', namespace: 'Lowkey::MockClass', source: nil) }

  let(:node) do
    root_node = Prism.parse_file('spec/fixtures/mock_node.rbx').value
    root_node.breadth_first_search { |n| n.instance_of?(Prism::ClassNode) }
  end

  describe '.[]' do
    context 'with method proxy' do
      before do
        source = Lowkey::Source.new(file_path: 'mock/path', scope: 'mock scope', lines: [], start_line: 123)
        method_proxy = Lowkey::MethodProxy.new(name: 'mock name', source:)
        class_proxy.keyed_methods[:render] = method_proxy
      end

      it 'returns a method proxy' do
        expect(class_proxy[:render]).to be_an_instance_of(Lowkey::MethodProxy)
      end

      it 'returns a method node' do
        expect(class_proxy['.render']).to be_an_instance_of(Prism::DefNode)
      end
    end
  end

  describe '#add_method_call' do
    subject(:class_proxy) { described_class.new(node:, name: 'MockClass', namespace: 'Lowkey::MockClass', source:) }

    let(:source) { Lowkey::Source.new(file_path: 'mock/path', scope: 'MockClass', lines: [], start_line: 1) }

    before do
      %i[get get post delete].each { |name| class_proxy.add_method_call(node: MockCallNode.new(name)) }
    end

    subject(:method_calls) { class_proxy.method_calls }

    it 'adds method calls' do
      expect(method_calls.map(&:name)).to eq(%i[get get post delete])
    end

    it 'adds method calls after method calls are built' do
      method_calls
      class_proxy.add_method_call(node: MockCallNode.new(:put))

      expect(class_proxy.method_calls.map(&:name)).to eq(%i[get get post delete put])
    end
  end
end
