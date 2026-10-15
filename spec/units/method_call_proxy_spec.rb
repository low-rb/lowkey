# frozen_string_literal: true

require_relative '../../lib/lowkey'

RSpec.describe Lowkey::MethodCallProxy do
  subject(:file_proxy) { Lowkey.load('spec/fixtures/method_calls.rb', cache: false) }

  let(:method_calls) { file_proxy['Lowkey::MethodCalls'].method_calls }

  def method_call(name, file_proxy_key = 'Lowkey::MethodCalls')
    file_proxy[file_proxy_key].method_calls.find { |method_call| method_call.name == name }
  end

  describe 'ModuleProxy#method_calls' do
    let(:module_proxy) { file_proxy['Lowkey::MethodCalls'] }

    it 'builds method call proxies for classes on load for adapters' do
      expect(module_proxy.instance_variable_get(:@method_calls)).not_to be_nil
    end

    it 'builds method call proxies for modules on first access' do
      expect(file_proxy['Object'].instance_variable_get(:@method_calls)).to be_nil
      expect(file_proxy['Object'].method_calls.map(&:name)).to eq([:require])
    end

    it 'builds a method call proxy for each method call node' do
      expect(module_proxy.method_calls.map(&:node)).to all(be_a(Prism::CallNode))
      expect(module_proxy.method_calls.map(&:name)).to include(:include, :attribute, :attr_reader, :type)
    end

    it 'returns the same method call proxies' do
      expect(module_proxy.method_calls).to be(module_proxy.method_calls)
    end
  end

  describe 'lazy attributes' do
    it 'builds the source on first access' do
      expect(method_call(:include).instance_variable_get(:@source)).to be_nil
      expect(method_call(:include).start_line).to eq(7)
    end

    it 'reads arguments from the node on first access' do
      expect(method_call(:include).instance_variable_defined?(:@arguments)).to be(false)
      expect(method_call(:include).arguments).to eq(['Comparable'])
    end
  end

  describe 'attributes' do
    it 'records top level method calls on Object' do
      expect(method_call(:require, 'Object').arguments).to eq(["'json'"])
    end

    it 'has arguments' do
      expect(method_call(:include).arguments).to eq(['Comparable'])
    end

    it 'has keywords' do
      expect(method_call(:attribute).keywords).to eq(%i[name age])
      expect(method_call(:attr_reader).keywords).to be_nil
    end

    it 'has the default value of a union' do
      types = method_calls.filter { |method_call| method_call.name == :type }
      expect(types.map(&:default)).to eq(["'café'", 'Integer'])
    end
  end

  describe '#rewrite' do
    it 'rewrites method calls on the same line from last to first' do
      types = method_calls.filter { |method_call| method_call.name == :type }
      types.sort_by { |method_call| -method_call.start_offset }.each { |method_call| method_call.rewrite(method_call.default) }

      expect(file_proxy.lines[11]).to eq("    def value = 'café' + Integer.to_s\n")
    end
  end

  describe '#remove' do
    it 'removes the line and the blank line orphaned after a class' do
      line_count = file_proxy.lines.count
      method_call(:include).remove

      expect(file_proxy.lines.join).to include("  class MethodCalls\n    attribute name: String, age: Integer\n")
      expect(file_proxy.lines.count).to eq(line_count)
    end

    it 'only removes once' do
      method_call(:include).remove

      expect { method_call(:include).remove }.not_to(change { file_proxy.lines.dup })
    end

    it 'keeps a blank line between other code' do
      method_call(:require, 'Object').remove

      expect(file_proxy.lines.join).to start_with("# frozen_string_literal: true\n\nmodule Lowkey\n")
    end
  end
end
