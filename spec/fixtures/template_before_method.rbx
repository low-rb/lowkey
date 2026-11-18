# frozen_string_literal: true

module Lowkey
  class TemplateBeforeMethod
    def render(event:)
      <div>{@link} — {"crème"} {</div>
    end

    private

    def link(page)
      "/posts?#{page}"
    end
  end
end
