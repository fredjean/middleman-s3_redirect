require 'middleman-core'

module Middleman
  module S3Redirect
    class Options
      attr_accessor \
        :prefix,
        :public_path,
        :bucket,
        :region,
        :path_style,
        :aws_access_key_id,
        :aws_secret_access_key,
        :after_build

      def initialize
        self.read_config
      end

      def redirect(from, to)
        redirects << RedirectEntry.new(from, to)
      end

      def redirects
        @redirects ||= []
      end

      protected

      def read_config(io = nil)
        unless io
          root_path = ::Middleman::Application.root
          config_file_path = File.join(root_path, ".s3_sync")

          # skip if config file does not exist
          return unless File.exists?(config_file_path)

          io = File.open(config_file_path, "r")
        end

        config = YAML.load(io)

        self.aws_access_key_id = config["aws_access_key_id"] if config["aws_access_key_id"]
        self.aws_secret_access_key = config["aws_secret_access_key"] if config["aws_secret_access_key"]
      end

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
          path.sub(/^\//, '')
        end
      end

    end

    class << self
      def options
        @@options
      end

      def registered(app, options_hash = {}, &block)
        options = Options.new
        yield options if block_given?

        @@options = options

        app.send :include, Helpers

        options.public_path ||= "build"
        options.path_style = true if options.path_style.nil?

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
          :region => options.region,
          :path_style => options.path_style
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
          s3_redirect_options.redirect(from, to)
        end

        def s3_redirect_options
          ::Middleman::S3Redirect.options
        end
      end
    end
  end
end
