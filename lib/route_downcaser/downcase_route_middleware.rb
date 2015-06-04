module RouteDowncaser

  class DowncaseRouteMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      new_env = env.clone

      # Don't touch anything, if uri/path is part of exclude_patterns or only touch the ones in the whitelist
      if  use_whitelist_or_blacklist?(new_env) && new_env['REQUEST_METHOD'] == "GET"
        # Downcase request_uri and/or path_info if applicable

        new_env['REQUEST_URI'] = downcased_uri(new_env['REQUEST_URI']) if new_env['REQUEST_URI'].present?

        new_env['PATH_INFO'] = downcased_uri(new_env['PATH_INFO']) if new_env['PATH_INFO'].present?

        # If redirect configured, then return redirect request,
        # if either request_uri or path_info has changed
        if RouteDowncaser.redirect
          if new_env["REQUEST_URI"].present? and new_env["REQUEST_URI"] != env["REQUEST_URI"]
            return redirect_header(new_env["REQUEST_URI"])
          end

          if new_env["PATH_INFO"].present? and new_env["PATH_INFO"] != env["PATH_INFO"]
            return redirect_header(new_env["PATH_INFO"])
          end
        end

      end

      # Default just move to next chain in Rack callstack
      # calling with downcased uri if needed
      @app.call(new_env)

    end

    private

    def use_whitelist_or_blacklist?(new_env)
      if RouteDowncaser.use_whitelist
        whitelist_patterns(new_env)
      else
        exclude_patterns(new_env)
      end
    end

    def exclude_patterns(new_env)
      !exclude_patterns_match?(new_env['REQUEST_URI']) || !exclude_patterns_match?(new_env['PATH_INFO'])
    end

    def whitelist_patterns(new_env)
      !!whitelist_patterns_match?(new_env['REQUEST_URI']) || !!whitelist_patterns_match?(new_env['PATH_INFO']) unless RouteDowncaser.whitelist_patterns.empty?
    end

    def exclude_patterns_match?(uri)
      uri.match(Regexp.union(RouteDowncaser.exclude_patterns)) if uri and RouteDowncaser.exclude_patterns
    end

    def whitelist_patterns_match?(uri)
      uri.match(Regexp.union(RouteDowncaser.whitelist_patterns)) if uri
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
