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
end
