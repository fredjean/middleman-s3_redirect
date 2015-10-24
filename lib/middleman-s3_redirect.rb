require 'middleman-core'
require 'fog/aws'
require 'middleman-s3_redirect/version'
require 'middleman-s3_redirect/commands'

::Middleman::Extensions.register(:s3_redirect, '>= 3.0.0') do
  require 'middleman-s3_redirect/extension'
  ::Middleman::S3Redirect
end
