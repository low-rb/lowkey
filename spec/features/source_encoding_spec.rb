# frozen_string_literal: true

require 'open3'
require 'rbconfig'

# Ruby reads source files as UTF-8 whatever the locale, so Lowkey does too. A build server without a UTF-8 locale,
# like Cloudflare Pages, reads files as US-ASCII by default, where a template's "—" is an invalid byte.
RSpec.describe 'A file with UTF-8 characters, read without a UTF-8 locale' do
  it 'is parsed as UTF-8' do
    script = <<~RUBY
      require 'lowkey'
      class_proxy = Lowkey.load('spec/fixtures/template_before_method.rbx', cache: false)['Lowkey::TemplateBeforeMethod']
      print class_proxy.instance_methods.keys.join(',')
    RUBY
    lib = File.expand_path('../../lib', __dir__)
    output, status = Open3.capture2e({ 'LANG' => 'C', 'LC_ALL' => 'C' }, RbConfig.ruby, '-E', 'US-ASCII', '-I', lib, '-e', script)

    expect(status.success?).to be(true), output
    expect(output).to eq('render,link')
  end
end
