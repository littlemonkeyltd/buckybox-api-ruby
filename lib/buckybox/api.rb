require "cgi"
require "httparty"
require "crazy_money"
require "super_recursive_open_struct"

module BuckyBox
  class API
    ResponseError = Class.new(Exception)

    include HTTParty
    format :json
    base_uri "https://api.buckybox.com/v1"

    def initialize(headers)
      self.class.headers(headers)
    end

    def boxes(params = {embed: "extras,images,box_items"}, options = {})
      query :get, "/boxes", params, options, price: CrazyMoney
    end

    def box(id, params = {embed: "extras,images,box_items"}, options = {})
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
      customer = JSON.parse(json_customer)

      if customer['id']
        query :put, "/customers/#{customer['id']}", json_customer # TODO: replace by :patch
      else
        query :post, "/customers", json_customer
      end
    end

    def create_order(json_order)
      query :post, "/orders", json_order
    end

  private

    def check_response!(response)
      unless [200, 201].include? response.code
        message = response.parsed_response["message"] || response.parsed_response
        message = "Error #{response.code} - #{message}"
        raise ResponseError, message
      end
    end

    def query(type, uri, params = {}, options = {}, types = {})
      options = {
        as_object: true
      }.merge(options)

      hash = query_cache(type, uri, params, types)

      if options[:as_object]
        SuperRecursiveOpenStruct.new(hash)
      else
        hash
      end.freeze
    end

    def query_cache(type, uri, params, types)
      query_fresh = -> {
        params_key = (type == :get ? :query : :body)
        response = self.class.public_send(type, uri, params_key => params)
        check_response!(response)
        parsed_response = response.parsed_response
        add_types(parsed_response, types)
      }

      if type == :get # NOTE: only cache GET method
        cache_key = [self.class.headers.hash, uri, to_query(params)].join

        @cache ||= {}
        @cache[cache_key] ||= query_fresh.call
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
        ''
      else
        hash.map do |key, value|
          "#{CGI.escape(key.to_s)}=#{CGI.escape(value)}"
        end.sort!.join("&")
      end
    end
  end
end
