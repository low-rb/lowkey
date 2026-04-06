# frozen_string_literal: true

require_relative '../../../lib/lowkey'
require_relative '../../../lib/visitors/method_call_visitor'

RSpec.describe Lowkey::MethodCallVisitor do
  let(:file_path) { 'spec/fixtures/dependencies/a.rb' }

  describe '#visit' do
    let(:file_proxy) { Lowkey.load(file_path, cache: false) }

    it 'identifies dependencies' do
      expect(file_proxy.dependencies).to eq(Set.new(['Lowkey::A::B']))
    end
  end
  
  describe 'private method inheritance' do
    let(:file_path) { 'spec/fixtures/private_inheritance.rb' }
    let(:file_proxy) { Lowkey.load(file_path, cache: false) }

    it 'tracks private visibility correctly without leaking to subclass' do
      parent = file_proxy["Parent"]
      child = file_proxy["Child"]

      expect(parent.private_start_line).not_to be_nil
      expect(child.private_start_line).to be_nil
    end
  end
end