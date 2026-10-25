# frozen_string_literal: true

require_relative '../../lib/lowkey'

RSpec.describe Lowkey::ValueParser, 'without Prism' do
  # Values Raindown and Antlers directives use, and the edge cases around them, read as Prism reads them.
  inputs = [
    'nil', 'true', 'false', ' true ',
    '0', '-0', '7', '-42', '1000000', '007', '010', '1_000', '0x1F', '0b101', '1e3', '12r', '3i',
    '0.0', '-0.0', '1.5', '-1.5', '1.50', '1.5e-3', '1.', '-',
    "'notes'", "''", "'data/downloads.csv'", "'3 5 2 8 6 9 4 7'", "  'padded'  ", "'it\\'s'", "'back\\\\slash'",
    "'a' 'b'", "'unterminated", %("x"), %(""), %("tab\\there"), %("\#{name}"), %("\#@name"), %("say \\"hi\\""),
    ':x', ':x?', ':save!', ':X', ':foo_bar', ':"two words"', ':foo=', ':+', ':', ':1',
    'title', 'author.name', 'tags', '-x', '1 + 1', 'nil?', 'truey',
    '-0x1F', '0o17', '08', '1__0', '1_000.5', '1E3', '-1.5e+2', '0_7', '1.5_0', '1.e3', '0b2',
    "'a\\nb'", "'\\q'", %("\\u00e9"), %("\\u{1F600}"), %("é"), %("\\\#{name}"), %("a\\sb"), %("\\e"), %("\\x41"), %("\\101"),
    %("\\\\\#{x}"), %("a\nb"), %(':a'), ':<=>', ':[]=', ':-@', ':**', ':!', ':=', ':a?b', %(:"a\\tb"), %(:"\#{x}")
  ]

  def outcome(method, input)
    value = described_class.public_send(method, input) { :not_a_value }
    [value, value.class]
  end

  inputs.each do |input|
    it "reads #{input.inspect} like Prism does" do
      expect(outcome(:parse, input)).to eq(outcome(:prism_parse, input))
    end
  end

  it 'never parses with Prism' do
    allow(described_class).to receive(:prism_parse)

    inputs.each { |input| described_class.parse(input) { nil } }

    expect(described_class).not_to have_received(:prism_parse)
  end
end
