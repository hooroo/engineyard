require 'highline'
require 'engineyard-api-client'
require 'engineyard/eyrc'

module EY
  class CLI
    class API
      def self.authenticate
        EY.ui.info("We need to fetch your API token; please log in.")
        begin
          email    = EY.ui.ask("Email: ")
          password = EY.ui.ask("Password: ", true)
          token = EY::APIClient.authenticate(email, password)
          EY::EYRC.load.api_token = token
          token
        rescue EY::APIClient::InvalidCredentials
          EY.ui.warn "Invalid username or password; please try again."
          retry
        end
      end

      attr_reader :token

      def initialize(endpoint)
        EY::APIClient.endpoint = endpoint

        @token = ENV['ENGINEYARD_API_TOKEN'] if ENV['ENGINEYARD_API_TOKEN']
        @token ||= EY::EYRC.load.api_token
        @token ||= self.class.authenticate

        unless @token
          raise EY::Error, "Sorry, we couldn't get your API token."
        end

        @api = EY::APIClient.new(@token)
      end

      protected

      def respond_to?(meth)
        super or @api.respond_to?(meth)
      end

      def method_missing(meth, *args, &block)
        if @api.respond_to?(meth)
          @api.send(meth, *args, &block)
        else
          super
        end
      end

    end
  end
end
