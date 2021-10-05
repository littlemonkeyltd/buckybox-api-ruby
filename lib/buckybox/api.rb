require "cgi"
require "crazy_money"
require "hashie/mash"
require "oj"
require "typhoeus"

module BuckyBox
  class API
    ResponseError = Class.new(Exception) # generic error
    NotFoundError = Class.new(ResponseError)

    ENDPOINTS = {
      production:  "https://api.grown.co.nz/v1",
      staging:     "https://api-staging.homegrown.kiwi/v1",
      development: "http://api.buckybox.homegrown.kiwi/v1",
      test:        "https://api.homergrown.kiwi/v1",
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
      attr_reader :response

      def initialize(response)
        @response, @cached_at = response, epoch
      end

      def expired?
        epoch - @cached_at > 60 # NOTE: cache responses for 60 seconds
      end

      private def epoch
        Time.now.utc.to_i
      end
    end

    def self.fixtures_path
      File.expand_path("../../../fixtures", __FILE__)
    end

    def initialize(headers)
      @headers = headers.freeze
      @endpoint = ENDPOINTS.fetch(ENV.fetch("RAILS_ENV", :production).to_sym)
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

    def handle_error!(response)
      parsed_response = parse_response(response)
      message = if parsed_response
        parsed_response["message"] || parsed_response
      else
        "Empty response"
      end

      message = "Error #{response.code} - #{message}"

      raise exception_type(response.code), message
    end

    def parse_response(response)
      Oj.load(response.body)
    end

    def exception_type(http_code)
      {
        404 => NotFoundError,
      }.fetch(http_code, ResponseError)
    end

    def query(method, path, params = {}, options = {}, types = {})
      options = { as_object: true }.merge(options)
      hash = query_cache(method, path, params, types)

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

    def query_cache(method, path, params, types)
      uri = [@endpoint, path].join

      query_fresh = lambda do
        params_key = (method == :get ? :params : :body)

        response = Typhoeus::Request.new(
          uri,
          headers: @headers,
          method: method,
          params_key => params,
          accept_encoding: "gzip",
        ).run

        handle_error!(response) unless response.success?
        parsed_response = parse_response(response)
        add_types(parsed_response, types)
      end

      if method == :get # NOTE: only cache GET method
        @cache ||= {}
        cache_key = [@headers.hash, uri, to_query(params)].join
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
