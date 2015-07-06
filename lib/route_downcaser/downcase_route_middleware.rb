module RouteDowncaser

  class DowncaseRouteMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)

      if RouteDowncaser.redirect
        # Don't touch anything, if uri/path is part of exclude_patterns
        if (!exclude_patterns_match?(env['REQUEST_URI']) ||
            !exclude_patterns_match?(env['PATH_INFO'])) && env['REQUEST_METHOD'] == "GET"

          url = downcased_uri(env['REQUEST_URI'] || env['PATH_INFO'])

          #redirect request if either request_uri or path_info has changed
          if url != (env['REQUEST_URI'] || env['PATH_INFO'])
            return redirect_header(url)
          end

        end
      end
      # Default just move to next chain in Rack callstack
      # calling with downcased uri if needed
      @app.call(env)

    end

    private

    def exclude_patterns_match?(uri)
      uri.match(Regexp.union(RouteDowncaser.exclude_patterns)) if uri and RouteDowncaser.exclude_patterns
    end

    def downcased_uri(uri)
      if has_querystring?(uri)
        "#{path(uri).downcase}?#{querystring(uri)}"
      else
        path(uri).downcase
      end
    end

    def path(uri)
      uri_items(uri).first
    end

    def querystring(uri)
      uri_items(uri).last
    end

    def has_querystring?(uri)
      uri_items(uri).length > 1
    end

    def uri_items(uri)
      uri.split('?')
    end

    def redirect_header(uri)
      [301, {'Location' => uri, 'Content-Type' => 'text/html'}, []]
    end
  end

end
