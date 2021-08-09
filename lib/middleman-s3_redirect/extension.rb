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
        :aws_session_token,
        :after_build,
        :acl

      def initialize
        self.read_config

        self.aws_access_key_id ||= ENV['AWS_ACCESS_KEY_ID']
        self.aws_secret_access_key ||= ENV['AWS_SECRET_ACCESS_KEY']
        self.aws_session_token ||= (ENV['AWS_SESSION_TOKEN'] || ENV['AWS_SECURITY_TOKEN'])
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
        self.aws_session_token = config["aws_session_token"] if config["aws_session_token"]
        self.acl = config["acl"] ? config["acl"] : 'public-read'
      end

      class RedirectEntry
        attr_reader :from, :to
        def initialize(from, to)
          @from = normalize(from)
          @to = to
        end

        protected
        def normalize(path)
          # paths without a slash are preserved as is: e.g. path => path, or path.html => path.html
          # paths with a slash get an index.html: e.g. path/ => path/index.html
          # paths with a preceding slash, have the preceding slash removed
          path << 'index.html' if path =~ /\/$/
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
            :acl => options.acl,
            :body => '',
            'x-amz-website-redirect-location' => "#{redirect.to}"
          }.merge(options.acl ? {} : {public: true}))
        end
      end

      def connection
        connection_options = {
          :region => options.region,
          :path_style => options.path_style
        }

        if options.aws_access_key_id && options.aws_secret_access_key
          connection_options.merge!({
            :aws_access_key_id => options.aws_access_key_id,
            :aws_secret_access_key => options.aws_secret_access_key
          })

          # If using a assumed role
          connection_options.merge!({
            :aws_session_token => options.aws_session_token
          }) if options.aws_session_token
        else
          connection_options.merge!({ :use_iam_profile => true })
        end

        @connection ||= Fog::Storage::AWS.new(connection_options)
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
