# BuckyBox::API

[![Dependency Status](http://img.shields.io/gemnasium/buckybox/buckybox-api-ruby.svg)](https://gemnasium.com/buckybox/buckybox-api-ruby)
[![Code Climate](http://img.shields.io/codeclimate/github/buckybox/buckybox-api-ruby.svg)](https://codeclimate.com/github/buckybox/buckybox-api-ruby)
[![Gem Version](http://img.shields.io/gem/v/buckybox-api.svg)](https://rubygems.org/gems/buckybox-api)

https://api.buckybox.com/docs

## Usage

```ruby
require "buckybox/api"

class YourClass

  def boxes
    api.boxes
  end

  private def api
    @api ||= BuckyBox::API.new(
      "API-Key" => "your API key",
      "API-Secret" => "your API secret",
    )
  end

end

YourClass.new.boxes #=> some JSON
```

## License

LGPLv3

