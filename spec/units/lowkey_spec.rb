# frozen_string_literal: true

require_relative '../../lib/lowkey'
require_relative '../../lib/proxies/file_proxy'

RSpec.describe Lowkey do
  let(:file_path) { 'spec/fixtures/extend_module.rb' }

  after do
    Lowkey.clear
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
        expect(Lowkey['spec/fixtures/extend_module.rb']).to be_nil
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
  end

  describe '.freeze_config!' do
    after { Lowkey.instance_variable_set(:@config, nil) }

    it 'freezes the config object' do
      Lowkey.freeze_config!

      expect(Lowkey.config).to be_frozen
    end

    it 'prevents further mutation via #configure' do
      Lowkey.freeze_config!

      expect { Lowkey.configure { |config| config.cache = false } }.to raise_error(FrozenError)
    end
  end

  describe '.make_shareable!' do
    # keys.clear on a frozen Hash raises FrozenError -- reset the ivar directly instead,
    # so the outer `after { Lowkey.clear }` still has a fresh, unfrozen Hash to work with.
    after { Lowkey.instance_variable_set(:@keys, nil) }

    it 'makes the registry shareable across Ractors' do
      Lowkey.load(file_path)

      Lowkey.make_shareable!

      ractor = Ractor.new do
        Lowkey['spec/fixtures/extend_module.rb']
      rescue StandardError => e
        e
      end
      expect(ractor.take).to be_an_instance_of(Lowkey::FileProxy)
    end
  end
end
