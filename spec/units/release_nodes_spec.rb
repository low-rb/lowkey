# frozen_string_literal: true

require_relative '../../lib/lowkey'

RSpec.describe 'Releasing nodes' do
  subject(:file_proxy) { Lowkey.load('spec/fixtures/method_calls.rb', cache: false) }

  let(:class_proxy) { file_proxy['Lowkey::MethodCalls'] }

  context 'when release_nodes is enabled' do
    before { Lowkey.configure { |config| config.release_nodes = true } }
    after { Lowkey.configure { |config| config.release_nodes = false } }

    it 'releases nodes once the file is loaded' do
      expect(file_proxy.instance_variable_get(:@root_node)).to be_nil
      expect(class_proxy.instance_variable_get(:@node)).to be_nil
    end

    it 'raises an error when a node is needed' do
      expect { file_proxy.root_node }.to raise_error(Lowkey::ReleasedNodeError, /release_nodes = false/)
      expect { class_proxy.node }.to raise_error(Lowkey::ReleasedNodeError)
      expect { class_proxy[:value].node }.to raise_error(Lowkey::ReleasedNodeError)
    end

    it 'raises an error when method calls are read from their nodes' do
      expect { file_proxy['Object'].method_calls }.to raise_error(Lowkey::ReleasedNodeError)
      # Method call proxies of classes are built on load by adapters.
      expect { class_proxy.method_calls.first.arguments }.to raise_error(Lowkey::ReleasedNodeError)
    end

    it 'keeps what proxies read from their source' do
      expect(class_proxy[:value].start_line).to eq(12)
      expect(class_proxy.method_calls.map(&:name)).to include(:include, :attr_reader)
    end

    it 'keeps the file path and lines of method calls' do
      expect(class_proxy.method_calls.first.file_path).to eq('spec/fixtures/method_calls.rb')
      expect(class_proxy.method_calls.first.lines).to be(file_proxy.lines)
    end

    it 'keeps nodes when loading with release_nodes: false' do
      file_proxy = Lowkey.load('spec/fixtures/method_calls.rb', cache: false, release_nodes: false)
      expect(file_proxy.root_node).to be_a(Prism::ProgramNode)
    end
  end

  context 'when release_nodes is disabled' do
    it 'keeps nodes once the file is loaded' do
      expect(file_proxy.root_node).to be_a(Prism::ProgramNode)
      expect(class_proxy.node).to be_a(Prism::ClassNode)
      expect(class_proxy[:value].node).to be_a(Prism::DefNode)
    end

    it 'releases nodes when loading with release_nodes: true' do
      file_proxy = Lowkey.load('spec/fixtures/method_calls.rb', cache: false, release_nodes: true)
      expect { file_proxy.root_node }.to raise_error(Lowkey::ReleasedNodeError)
    end
  end
end
