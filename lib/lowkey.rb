# frozen_string_literal: true

require 'prism'

require_relative 'adapters/adapter_loader'
require_relative 'factories/proxy_factory'
require_relative 'maps/parent_map'
require_relative 'visitors/visitor'
require_relative 'proxies/file_proxy'

module Lowkey
  NAMESPACE_PATTERN = /\A[A-Z]\w*(::[A-Z]\w*)*\z/

  class << self
    def keys
      @keys ||= {}
    end

    # A namespace returns its file proxies. A file path returns its file proxy, loading the file on first access.
    def [](key)
      return keys[key] if keys.key?(key) || !file_path?(key)

      load(key)
    end

    def load(file_path, cache: true)
      root_node = Prism.parse(File.read(file_path), filepath: file_path).value
      file_proxy = ProxyFactory.file_proxy(root_node:, file_path:)

      parent_map = ParentMap.new(root_node:)
      visitor = Visitor.new(file_proxy:, parent_map:)
      root_node.accept(visitor)

      AdapterLoader.load(file_proxy:)

      if Lowkey.config.cache && cache
        map_file_path(file_proxy:)
        map_definitions(file_proxy:)
      end

      file_proxy
    end

    def clear
      keys.clear
    end

    def config
      config = Struct.new(:cache)
      @config ||= config.new(true)
    end

    def configure
      yield(config)
    end

    private

    def file_path?(key)
      key.is_a?(String) && !key.match?(NAMESPACE_PATTERN) && File.file?(key)
    end

    def map_file_path(file_proxy:)
      keys[file_proxy.file_path] = file_proxy

      # Map absolute paths to project root/relative paths.
      project_path = file_proxy.file_path.delete_prefix(Dir.pwd).delete_prefix('/')
      keys[project_path] = file_proxy if project_path != file_proxy.file_path
    end

    def map_definitions(file_proxy:)
      file_proxy.definitions.each_key do |namespace|
        keys[namespace] ||= []
        keys[namespace] << file_proxy
      end
    end
  end
end
