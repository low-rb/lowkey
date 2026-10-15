# frozen_string_literal: true

require_relative '../../lib/lowkey'
require_relative '../../lib/proxies/file_proxy'

RSpec.describe Lowkey do
  let(:file_path) { 'spec/fixtures/extend_module.rb' }

  after do
    Lowkey.clear(keep: false)
  end

  describe '.load' do
    let(:file_proxy) { Lowkey.load(file_path) }

    it 'returns file proxy' do
      expect(file_proxy).to be_an_instance_of(Lowkey::FileProxy)
    end

    it 'caches file proxy' do
      file_proxy
      expect(Lowkey['spec/fixtures/extend_module.rb']).to be_an_instance_of(Lowkey::FileProxy)
    end

    context 'without caching' do
      before do
        Lowkey.configure { |config| config.cache = false }
      end

      after do
        Lowkey.configure { |config| config.cache = true }
      end

      it 'does not cache file proxy' do
        file_proxy
        expect(Lowkey.keys).not_to have_key('spec/fixtures/extend_module.rb')
      end
    end
  end

  describe '.[]' do
    before do
      Lowkey.load(file_path)
    end

    it 'maps file path to file proxy' do
      expect(Lowkey['spec/fixtures/extend_module.rb']).to be_an_instance_of(Lowkey::FileProxy)
    end

    it 'maps namespace to file proxies' do
      expect(Lowkey['Lowkey::ExtendModule'].first).to be_an_instance_of(Lowkey::FileProxy)
    end

    it 'returns the cached file proxy' do
      expect(Lowkey[file_path]).to be(Lowkey[file_path])
    end

    context 'when the file is not loaded' do
      let(:file_path) { 'spec/fixtures/mock_module.rb' }

      before { Lowkey.clear }

      it 'loads the file proxy on first access and caches it' do
        expect(Lowkey).to receive(:load).with(file_path).once.and_call_original

        file_proxy = Lowkey[file_path]

        expect(file_proxy).to be_an_instance_of(Lowkey::FileProxy)
        expect(Lowkey[file_path]).to be(file_proxy)
      end
    end

    it 'does not load a namespace or a missing file' do
      expect(Lowkey['Lowkey::Missing']).to be_nil
      expect(Lowkey['spec/fixtures/missing.rb']).to be_nil
    end
  end

  describe '.clear' do
    let(:kept_path) { 'spec/fixtures/extend_module.rb' }
    let(:cleared_path) { 'spec/fixtures/mock_module.rb' }

    before do
      Lowkey.keep(Lowkey[kept_path])
      Lowkey.load(cleared_path)
      Lowkey.clear
    end

    it 'keeps file proxies and their namespaces' do
      expect(Lowkey.keys).to have_key(kept_path)
      expect(Lowkey.keys['Lowkey::ExtendModule']).to all(be_an_instance_of(Lowkey::FileProxy))
    end

    it 'clears file proxies that are not kept' do
      expect(Lowkey.keys).not_to have_key(cleared_path)
      expect(Lowkey.keys.values.flatten).to all(satisfy { |file_proxy| Lowkey.kept.include?(file_proxy) })
    end

    it 'clears everything when not keeping file proxies' do
      Lowkey.clear(keep: false)

      expect(Lowkey.keys).to be_empty
      expect(Lowkey.kept).to be_empty
    end
  end
end
