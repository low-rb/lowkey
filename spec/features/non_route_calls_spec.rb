# frozen_string_literal: true

require_relative '../../lib/lowkey'

RSpec.describe 'Calls named like routes' do
  it 'ignores calls that have no route pattern' do
    file_proxy = Lowkey.load('spec/fixtures/non_route_calls.rb')

    expect(file_proxy.definitions['Lowkey::NonRouteCalls'].keyed_methods).to be_empty
  end
end
