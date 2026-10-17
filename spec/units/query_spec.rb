# frozen_string_literal: true

require 'prism'
require_relative '../../lib/lowkey'

RSpec.describe Lowkey::Query do
  subject(:query) { Class.new { include Lowkey::Query }.new }

  let(:root_node) { Prism.parse(source).value }
  let(:parent_map) { Lowkey::ParentMap.new(root_node:) }

  def call(name)
    root_node.breadth_first_search { |node| node.is_a?(Prism::CallNode) && node.name == name }
  end

  describe '#namespace' do
    let(:source) do
      <<~RUBY
        top_level

        module Outer
          class Inner
            first
            second
          end

          module_level
        end
      RUBY
    end

    it 'is Object at the top level' do
      expect(query.namespace(node: call(:top_level), parent_map:)).to eq('Object')
    end

    it 'joins nested namespaces' do
      expect(query.namespace(node: call(:first), parent_map:)).to eq('Outer::Inner')
      expect(query.namespace(node: call(:module_level), parent_map:)).to eq('Outer')
    end

    it 'reuses the cached namespace of an ancestor' do
      first = query.namespace(node: call(:first), parent_map:)
      expect(query.namespace(node: call(:second), parent_map:)).to be(first)
    end

    context 'when a class name is missing' do
      let(:source) { "class < Base\n  call_in_class\nend\n" }

      it 'has no namespace' do
        expect(query.namespace(node: call(:call_in_class), parent_map:)).to be_nil
      end
    end
  end
end
