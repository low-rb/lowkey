# frozen_string_literal: true

require 'prism'

require_relative 'adapters/adapter_loader'
require_relative 'factories/proxy_factory'
require_relative 'maps/parent_map'
require_relative 'visitors/visitor'
require_relative 'proxies/file_proxy'

module Lowkey
  class << self
    def keys
      @keys ||= {}
    end

    def [](key)
      keys[key]
    end

    def load(file_path, cache: true)
      root_node = Prism.parse_file(file_path).value
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

    # Freezes the config, making it shareable across Ractors (Class/Module instance
    # variables can only be read from a non-main Ractor if their value is frozen).
    # Call once, after all #configure calls, before spawning any worker Ractors --
    # #configure can no longer mutate the config afterward, same as any other frozen
    # object.
    def freeze_config!
      config.freeze
    end

    # Makes the whole file/class/method-proxy registry shareable across Ractors, so
    # a class LowType has already redefined can be called from a worker Ractor.
    # Call once boot is complete (every class that will ever call Lowkey.load has
    # done so) and before spawning any worker Ractors -- the registry is read-only
    # from that point on, same as any other frozen/shareable object.
    #
    # Raises Ractor::Error if anything in the registry isn't shareable even when
    # deep-frozen (e.g. a live Binding, an IO, a Proc closing over local state).
    # low_type's class_proxy.class_binding is cleared for exactly this reason --
    # if you're calling this from a fresh registry with no other unshareable
    # objects stored on a proxy, it should just work.
    def make_shareable!
      Ractor.make_shareable(keys)
    end

    private

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
