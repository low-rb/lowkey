# frozen_string_literal: true

require 'prism'
require_relative '../../lib/lowkey'

RSpec.describe Lowkey::ValueParser do
  def node(source)
    Prism.parse(source).value.statements.body.first
  end

  describe '.value?' do
    it 'is true for value nodes' do
      ['nil', 'true', 'false', "'a'", '"a"', '3', '-1.5', ':a'].each { |source| expect(described_class.value?(node(source))).to be(true) }
    end

    it 'is false for other nodes' do
      ['a', 'A', 'a.b', "\"\#{a}\"", '[1]', '{}'].each { |source| expect(described_class.value?(node(source))).to be(false) }
    end
  end

  describe '.value' do
    it 'reads the value of a node' do
      expect(described_class.value(node('nil'))).to be_nil
      expect(described_class.value(node('true'))).to be(true)
      expect(described_class.value(node('false'))).to be(false)
      expect(described_class.value(node(%q('it\'s')))).to eq("it's")
      expect(described_class.value(node('"a\tb"'))).to eq("a\tb")
      expect(described_class.value(node('-3'))).to eq(-3)
      expect(described_class.value(node('1.5'))).to eq(1.5)
      expect(described_class.value(node(':draft'))).to eq(:draft)
    end

    it 'returns what the block returns for other nodes' do
      expect(described_class.value(node('a')) { :other }).to eq(:other)
    end
  end

  describe '.parse' do
    it 'reads a value from text' do
      expect(described_class.parse(" 'a' ") { :other }).to eq('a')
      expect(described_class.parse('3') { :other }).to eq(3)
      expect(described_class.parse(':draft') { :other }).to eq(:draft)
      expect(described_class.parse('nil') { :other }).to be_nil
      expect(described_class.parse('false') { :other }).to be(false)
    end

    it 'returns what the block returns for anything else' do
      ['title', 'page.title', '@title', 'nil?', 'true.to_s', "\"\#{exit}\"", "'a' 'b'", '1; exit', '`ls`', "'a", ''].each do |text|
        expect(described_class.parse(text) { :other }).to eq(:other)
      end
    end

    it 'gives the block the text' do
      expect(described_class.parse('title', &:upcase)).to eq('TITLE')
    end

    it 'never runs code' do
      expect(described_class.parse('exit') { :other }).to eq(:other)
    end
  end
end
