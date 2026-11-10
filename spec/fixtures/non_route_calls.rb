# frozen_string_literal: true

# Parsed by Lowkey but never required, since the call would run.
module Lowkey
  class NonRouteCalls
    get(URI('https://example.com'))
  end
end
