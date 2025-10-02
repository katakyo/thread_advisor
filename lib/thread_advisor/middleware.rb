# frozen_string_literal: true

module ThreadAdvisor
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      tag = ThreadAdvisor.config.middleware_tag_resolver.call(env)
      result, _metrics = ThreadAdvisor.measure(tag) { @app.call(env) }
      result
    end
  end
end
