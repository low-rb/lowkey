# frozen_string_literal: true

require_relative '../../lib/lowkey'

# Prism can't read a template, like RBX's HTML, so it guesses where a method holding one ends.
# Here "</div>" starts a regex that runs on into the next method's string, so Prism ends "render" with the class.
RSpec.describe 'A method holding a template' do
  subject(:render_method) { Lowkey.load('spec/fixtures/template_before_method.rbx', cache: false)['Lowkey::TemplateBeforeMethod'][:render] }

  it 'ends at the "end" lined up with its "def"' do
    expect(render_method.body.export).to eq("      <div>{@link}</div>\n")
  end
end
