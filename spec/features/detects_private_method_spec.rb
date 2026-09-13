# frozen_string_literal: true

require_relative '../../lib/lowkey'

RSpec.describe 'Private method visibility' do
  let(:file_path) { 'spec/fixtures/visibility_test.rb' }
  let(:file_proxy) { Lowkey.load(file_path, cache: false) }

  it 'detects that a class has private methods' do
    target_class = file_proxy["VisibilityTest"] 

    expect(target_class.private_start_line).not_to be_nil
  end
end
