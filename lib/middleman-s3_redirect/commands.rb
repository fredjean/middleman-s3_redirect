require 'middleman-core/cli'
require 'middleman-s3_redirect/extension'

module Middleman
  module Cli
    class S3Redirect < Thor
      include Thor::Actions

      check_unknown_options!

      namespace :s3_redirect

      def self.exit_on_failure?
        true
      end

      desc "s3_redirect", "Creates redirect objects directly in S3."
      def s3_redirect
        shared_inst = ::Middleman::Application.server.inst
        if (!shared_inst.respond_to?('s3_redirect_options') ||
            !shared_inst.s3_redirect_options.bucket)
          raise Thor::Error.new "You need to activate this extension."
        end

        ::Middleman::S3Redirect.generate
      end
    end
  end
end
