# frozen_string_literal: true

require_relative '../../lib/lowkey'

# Prism can't read a template, like RBX's HTML. Here "</div>" would start a regex that runs on into the next method's
# string, so Lowkey masks the template and parses the file again.
RSpec.describe 'A method holding a template' do
  subject(:class_proxy) { Lowkey.load('spec/fixtures/template_before_method.rbx', cache: false)['Lowkey::TemplateBeforeMethod'] }

  it 'ends at the "end" lined up with its "def"' do
    expect(class_proxy[:render].body.export).to eq("      <div>{@link} — {\"crème\"} {</div>\n")
  end

  it 'leaves the methods below it to be found' do
    expect(class_proxy.instance_methods.keys).to eq(%i[render link])
  end

  it 'leaves the methods below it private' do
    expect(class_proxy.private_start_line).to eq(9)
  end

  it "keeps the methods below it at their place in the file, though the template's characters take more than a byte" do
    source = File.binread('spec/fixtures/template_before_method.rbx')
    param = class_proxy[:link][:page]

    expect(source.byteslice(param.source.start_offset, 4)).to eq('page')
  end
end
