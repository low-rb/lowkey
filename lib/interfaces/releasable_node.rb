# frozen_string_literal: true

module Lowkey
  class ReleasedNodeError < StandardError
    def initialize(message = 'Prism nodes are released once a file loads. Set "Lowkey.config.release_nodes = false" to keep them.')
      super
    end
  end

  # A proxy whose Prism node is released once its file loads, as nodes use most of a cached file's memory.
  module ReleasableNode
    def node
      raise ReleasedNodeError if @node_released

      @node
    end

    def release_node
      @node = nil
      @node_released = true
    end
  end
end
