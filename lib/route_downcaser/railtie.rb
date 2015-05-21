module RouteDowncaser
  class Railtie < Rails::Railtie
    initializer "add_downcase_route_middleware" do |app|
      app.config.middleware.insert_before 'Warden::Manager',
                                          'RouteDowncaser::DowncaseRouteMiddleware'
    end
  end
end
