module Sinatra
  class Controller
    attr_accessor :params, :request, :template_cache
    include Sinatra::Templates
    def initialize(params,request)
      @params  = params
      @request = request
      @template_cache = Tilt::Cache.new rescue 'sinatra < 1.0'
      @templates = {}
    end
    class << self
      def views
      end
      def templates
        {}
      end
    end
  end
  module Controllers
    class Mapping
      attr_accessor :klass, :opts

      def initialize(klass,opts={})
        @klass = klass
        @opts  = opts
      end

      def route(verb, path, action)
        aklass = klass # need this so it will stay in scope for closure
        block = proc { aklass.new(params, request).send action }
        if path[0] != '/'
          path = '/' + File.join(opts[:scope] || '', path)
        end
        Sinatra::Application.send verb, path, &block
      end

      def parse
        klass.instance_methods.each do |meth|
          verb,name = meth.to_s.scan(/^(get|post|delete|put)_(.*)$/).flatten
          next unless verb
          scope = '/' + (opts[:scope] || klass.to_s.downcase)
          scope.gsub!(%r{^/+},'/')
          route verb,"#{scope}/#{name.downcase}", meth
        end
      end

      # why are these even defined?
      undef_method :get, :post, :put, :delete
      def method_missing(method,*a)
        case method.to_s
        when /(get|post|delete|put)/
          route(method, *a)
        else
          super
        end
      end
    end

    class << self
      def register(klass, opts={}, &block)
        map = Mapping.new(klass,opts)
        map.instance_eval(&block) if block
        map.parse
      end
    end
  end
end
