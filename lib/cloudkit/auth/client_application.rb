require 'oauth'
require 'oauth/server'
module CloudKit
  module Auth
    class ClientApplication < ActiveRecord::Base
      belongs_to :user
      has_many :tokens, :class_name => "OauthToken"
      validates_presence_of :name, :url, :key, :secret
      validates_uniqueness_of :key
      before_validation_on_create :generate_keys

      def self.find_token(token_key)
        token = OauthToken.find_by_token(token_key, :include => :client_application)
        return token if token.authorized?
        nil
      end

      def self.verify_request(request, options = {}, &block)
        begin
          signature = OAuth::Signature.build(request, options, &block)
          return false unless OauthNonce.remember(signature.request.nonce, signature.request.timestamp)
          value = signature.verify
          value
        rescue OAuth::Signature::UnknownSignatureMethod => e
         false
        end
      end

      def oauth_server
        @oauth_server ||= OAuth::Server.new "http://your.site" # TODO
      end

      def credentials
        @oauth_client ||= OAuth::Consumer.new key,secret
      end

      def create_request_token
        RequestToken.create :client_application => self
      end

      protected

      def generate_keys
        @oauth_client = oauth_server.generate_consumer_credentials
        self.key = @oauth_client.key
        self.secret = @oauth_client.secret
      end
    end
  end
end