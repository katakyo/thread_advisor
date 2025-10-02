# frozen_string_literal: true

require "rails/railtie"

module ThreadAdvisor
  class Railtie < ::Rails::Railtie
    initializer "thread_advisor.middleware" do |app|
      app.middleware.use ThreadAdvisor::Middleware if ThreadAdvisor.config.enable_middleware
    end
  end
end
