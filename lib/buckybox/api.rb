require "httparty"

module BuckyBox
  class API
    include HTTParty
    format :json
    base_uri "https://api.buckybox.com/v0"
    # base_uri "http://api.buckybox.dev:3000/v0"

    class << self
      def boxes(embed: "extras,images,box_items")
        get("/boxes?embed=#{embed}").parsed_response
      end

      def box(id, embed: "extras,images,box_items")
        get("/boxes/#{id}?embed=#{embed}").parsed_response
      end
    end
  end
end
