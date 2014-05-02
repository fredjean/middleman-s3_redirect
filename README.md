# Middleman::S3Redirect

AWS S3 allows redirects to occur directly from an S3 object. This gem
automates configuring AWS S3 to redirect from one path to another.

## Installation

Add this line to your application's Gemfile:

    gem 'middleman-s3_redirect'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install middleman-s3_sync

## Usage

You need to add the following code to your ```config.rb``` file:

```ruby
activate :s3_redirect do |config|
  config.bucket                = 'my.bucket.com' # The name of the S3 bucket you are targetting. This is globally unique.
  config.region                = 'us-west-1'     # The AWS region for your bucket.
  config.aws_access_key_id     = 'AWS KEY ID'
  config.aws_secret_access_key = 'AWS SECRET KEY'
  config.after_build           = false # We chain after the build step by default. This may not be your desired behavior...
end
```

The ```redirect``` method register a redirect:

```ruby
redirect '/old/path', '/new/path'
```

You can then configure S3 to redirect these path by running  ```middleman s3_redirect```.

### Providing AWS Credentials

There are a few ways to provide the AWS credentials for s3_redirect:

#### Through ```config.rb```

You can set the aws_access_key_id and aws_secret_access_key in the block
that is passed to the activate method.

#### Through ```.s3_sync``` File

You can create a ```.s3_sync``` at the root of your middleman project.
The credentials are passed in the YAML format. The keys match the
options keys.

The .s3_sync file takes precedence to the configuration passed in the
activate method.

A sample ```.s3_sync``` file is included at the root of this repo.

#### Through Environment

You can also pass the credentials through environment variables. They
map to the following values:

| Setting               | Environment Variable               |
| --------------------- | ---------------------------------- |
| aws_access_key_id     | ```ENV['AWS_ACCESS_KEY_ID```       |
| aws_secret_access_key | ```ENV['AWS_SECRET_ACCESS_KEY']``` |

The environment is used when the credentials are not set in the activate
method or passed through the ```.s3_sync``` configuration file.

## A Debt of Gratitude

I used Middleman Sync as a template for building a Middleman extension.
The code is well structured and easy to understand and it was easy to
extend it to add my synchronization code. My gratitude goes to @karlfreeman
and is work on Middleman sync.

Many thanks to [Junya Ogura](https://github.com/juno) for multiple pull
requests improving this gem.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
