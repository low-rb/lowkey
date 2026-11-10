# frozen_string_literal: true

require 'open3'
require 'rbconfig'

# Prism takes a while to load, so Lowkey only loads it to parse. Each check runs in its own Ruby, as specs load Prism.
RSpec.describe 'Loading Prism' do
  def prism_loaded_after(code)
    script = "require 'lowkey'; #{code}; print defined?(Prism::Node) ? 'loaded' : 'not loaded'"
    output, status = Open3.capture2e(RbConfig.ruby, '-I', File.expand_path('../../lib', __dir__), '-e', script)
    raise output unless status.success?

    output
  end

  it 'waits until something is parsed' do
    expect(prism_loaded_after('nil')).to eq('not loaded')
  end

  it 'does not load for text that cannot be a value' do
    expect(prism_loaded_after("Lowkey::ValueParser.parse('title') { nil }")).to eq('not loaded')
  end

  it 'loads to parse a value' do
    expect(prism_loaded_after("raise unless Lowkey::ValueParser.parse(\"'notes'\") == 'notes'")).to eq('loaded')
  end

  it 'loads to parse a file' do
    expect(prism_loaded_after("Lowkey.load('spec/fixtures/class_methods.rb')")).to eq('loaded')
  end
end
