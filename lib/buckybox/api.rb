require "cgi"
require "crazy_money"
require "hashie/mash"
require "oj"
require "httparty"

module BuckyBox
  class API
    ResponseError = Class.new(Exception) # generic error
    NotFoundError = Class.new(Exception)

    ENDPOINTS = {
      production:  "https://api.buckybox.com/v1",
      staging:     "https://api-staging.buckybox.com/v1",
      development: "http://api.buckybox.local:3000/v1",
      test:        "https://api.buckybox.com/v1",
    }.freeze

    class Response < Hashie::Mash
      def initialize(hash)
        unless hash.is_a?(Hash)
          raise ArgumentError, "#{hash.inspect} must be a Hash"
        end

        super(hash, nil) do |object, key|
          raise NoMethodError, "undefined method `#{key}' for #{object}"
        end
      end
    end

    class CachedResponse
      attr_reader :response, :cached_at

      def initialize(response)
        @response, @cached_at = response, epoch
      end

      def expired?
        epoch - cached_at > 60 # NOTE: cache responses for 60 seconds
      end

      private def epoch
        Time.now.utc.to_i
      end
    end

    include HTTParty
    base_uri ENDPOINTS.fetch(ENV.fetch("RAILS_ENV", "production").to_sym)
    parser ->(body, _) { Oj.load(body) }

    def self.fixtures_path
      File.expand_path("../../../fixtures", __FILE__)
    end

    def initialize(headers)
      self.class.headers(headers)
    end

    def boxes(params = { embed: "images" }, options = {})
      query :get, "/boxes", params, options, price: CrazyMoney
    end

    def box(id, params = { embed: "extras,images,box_items" }, options = {})
      query :get, "/boxes/#{id}", params, options, price: CrazyMoney
    end

    def delivery_services(params = {}, options = {})
      query :get, "/delivery_services", params, options, fee: CrazyMoney
    end

    def delivery_service(id, params = {}, options = {})
      query :get, "/delivery_services/#{id}", params, options, fee: CrazyMoney
    end

    def webstore
      query :get, "/webstore"
    end

    def customers(params = {}, options = {})
      query :get, "/customers", params, options, account_balance: CrazyMoney
    end

    def customer(id, params = {}, options = {})
      query :get, "/customers/#{id}", params, options, account_balance: CrazyMoney
    end

    def authenticate_customer(params = {}, options = {})
      query :post, "/customers/sign_in", params, options
    end

    def create_or_update_customer(json_customer)
      customer = Oj.load(json_customer)

      if customer["id"]
        query :put, "/customers/#{customer['id']}", json_customer # TODO: replace by :patch
      else
        query :post, "/customers", json_customer
      end
    end

    def create_order(json_order)
      query :post, "/orders", json_order
    end

    def flush_cache!
      @cache = nil
    end

  private

    def check_response!(response)
      unless [200, 201].include? response.code
        message = if response.parsed_response
          response.parsed_response["message"] || response.parsed_response
        else
          "Empty response"
        end

        message = "Error #{response.code} - #{message}"

        raise exception_type(response.code), message
      end
    end

    def exception_type(http_code)
      {
        404 => NotFoundError,
      }.fetch(http_code, ResponseError)
    end

    def query(type, uri, params = {}, options = {}, types = {})
      options = {
        as_object: true,
      }.merge(options)

      hash = query_cache(type, uri, params, types)

      if options[:as_object]
        if hash.is_a?(Array)
          hash.map { |item| Response.new(item) }
        else
          Response.new(hash)
        end
      else
        hash
      end.freeze
    end

    def query_cache(type, uri, params, types)
      query_fresh = lambda do
        params_key = (type == :get ? :query : :body)
        response = self.class.public_send(type, uri, params_key => params)
        check_response!(response)
        parsed_response = response.parsed_response
        add_types(parsed_response, types)
      end

      if type == :get # NOTE: only cache GET method
        @cache ||= {}
        cache_key = [self.class.headers.hash, uri, to_query(params)].join
        cached_response = @cache[cache_key]

        if cached_response && !cached_response.expired?
          cached_response.response
        else
          response = query_fresh.call
          @cache[cache_key] = CachedResponse.new(response)
          response
        end
      else
        query_fresh.call
      end
    end

    def add_types(object, types)
      if object.is_a?(Array)
        object.map { |item| add_types(item, types) }
      else
        types.each do |attribute, type|
          attribute = attribute.to_s

          new_value = type.new object.fetch(attribute)
          object.store(attribute, new_value)
        end

        object
      end
    end

    def to_query(hash)
      if hash.empty?
        ""
      else
        hash.map do |key, value|
          "#{CGI.escape(key.to_s)}=#{CGI.escape(value)}"
        end.sort!.join("&")
      end
    end
  end
end
