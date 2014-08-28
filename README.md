# BuckyBox::API

https://api.buckybox.com/docs

## Usage

```ruby
require "buckybox/api"

class YourClass

  def boxes
    api.boxes
  end

  private def api
    @api ||= begin
      api = BuckyBox::API

      api.headers(
        "API-Key" => "your API key",
        "API-Secret" => "your API secret",
      )

      api
    end
  end

end

YourClass.new.boxes #=> some JSON
```

## License

LGPLv3

