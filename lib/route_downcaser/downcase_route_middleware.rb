module RouteDowncaser

  class DowncaseRouteMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      # Don't touch anything, if uri/path is part of exclude_patterns
      if (!exclude_patterns_match?(env['REQUEST_URI']) || !exclude_patterns_match?(env['PATH_INFO'])) && env['REQUEST_METHOD'] == "GET"
        # Downcase request_uri and/or path_info if applicable
        if env['REQUEST_URI'].present?
          request_uri = downcased_uri(env['REQUEST_URI'])
        end

        if env['PATH_INFO'].present?
          request_path_info = downcased_uri(env['PATH_INFO'])
        end

        # If redirect configured, then return redirect request,
        # if either request_uri or path_info has changed
        if RouteDowncaser.redirect
          if env["REQUEST_URI"].present? and request_uri != env["REQUEST_URI"]
            return redirect_header(request_uri)
          end

          if env["PATH_INFO"].present? and request_path_info != env["PATH_INFO"]
            return redirect_header(request_path_info)
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
