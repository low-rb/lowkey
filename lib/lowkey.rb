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

    def load(file_path, cache: true, release_nodes: config.release_nodes)
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

      file_proxy.release_nodes if release_nodes
      file_proxy
    end

    def kept
      @kept ||= Set.new
    end

    # Keeps a file proxy in the cache when it's cleared, for gems that look it up after the app has loaded.
    def keep(file_proxy)
      kept << file_proxy
    end

    # Clears cached file proxies to save memory, such as in a boot file once an app has loaded.
    # Kept file proxies stay along with their namespaces, unless "keep" is false.
    def clear(keep: true)
      kept.clear unless keep

      keys.select! do |_key, value|
        next kept.include?(value) unless value.is_a?(Array)

        value.select! { |file_proxy| kept.include?(file_proxy) }
        !value.empty?
      end
    end

    def config
      config = Struct.new(:cache, :release_nodes)
      @config ||= config.new(true, true)
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
