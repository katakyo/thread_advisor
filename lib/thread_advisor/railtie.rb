# frozen_string_literal: true

require "rails/railtie"

module ThreadAdvisor
  class Railtie < ::Rails::Railtie
    initializer "thread_advisor.middleware" do |app|
      if ThreadAdvisor.config.enable_middleware
        app.middleware.use ThreadAdvisor::Middleware
      end
    end
  end
end
