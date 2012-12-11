require 'middleman-core'

module Middleman
  module S3Redirect
    class Options < Struct.new(
      :prefix,
      :public_path,
      :bucket,
      :region,
      :aws_access_key_id,
      :aws_secret_access_key,
      :after_build
    )

      def redirect(from, to)
        redirects << RedirectEntry.new(from, to)
      end

      def redirects
        @redirects ||= []
      end

      protected
      class RedirectEntry
        attr_reader :from, :to
        def initialize(from, to)
          @from = normalize(from)
          @to = to
        end

        protected
        def normalize(path)
          unless path =~ /\.html$/
            path << '/' unless path =~ /\/$/
            path << 'index.html'
          end
          path = path[1..path.length] if path[0] = '/'
          path
        end
      end

    end
    
    class << self
      def options
        @@options
      end

      def registered(app, options_hash = {}, &block)
        options = Options.new(options.hash)
        yield options if block_given?

        @@options = options

        app.send :include, Helpers
        
        options.public_path ||= "build"

        app.after_configuration do |config|
          after_build do |builder|
            ::Middleman::S3Redirect.generate if options.after_build
          end
        end
      end
      alias :included :registered

      def generate
        options.redirects.each do |redirect|
          puts "Redirecting /#{redirect.from} to #{redirect.to}"
          bucket.files.create({
            :key => redirect.from,
            :public => true,
            :acl => 'public-read',
            :body => '',
            'x-amz-website-redirect-location' => "#{redirect.to}"
          })
        end
      end

      def connection
        @connection ||= Fog::Storage.new({
          :provider => 'AWS',
          :aws_access_key_id => options.aws_access_key_id,
          :aws_secret_access_key => options.aws_secret_access_key,
          :region => options.region
        })
      end

      def bucket
        @bucket ||= connection.directories.get(options.bucket)
      end

      def s3_files
        @s3_files ||= bucket.files
      end

      module Helpers
        def redirect(from, to)
          ::Middleman::S3Redirect.options.redirect(from, to)
        end
      end
    end
  end
end
