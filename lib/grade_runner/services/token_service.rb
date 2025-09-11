require "net/http"
require "oj"
require "active_support/core_ext/object/blank"

module GradeRunner
  module Services
    class TokenService
      attr_reader :submission_url

      # TODO: do we want to make this configurable?
      TOKEN_REGEX = /^[1-9A-Za-z][^OIl]{23}$/

      def initialize(submission_url)
        @submission_url = submission_url
      end

      def validate_token(token)
        return false unless token.is_a?(String) && token =~ TOKEN_REGEX

        url = "#{submission_url}/submissions/validate_token?token=#{token}"
        uri = URI.parse(url)
        req = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(req)
        end
        result = Oj.load(res.body)
        result["success"]
      rescue => e
        false
      end

      def get_token(input_token, file_token, config_file_name)
        if input_token.present?
          input_token
        elsif file_token.present?
          file_token
        else
          prompt_for_token(config_file_name)
        end
      end

      def prompt_for_token(config_file_name)
        puts "Enter your access token for this project"
        new_token = ""

        while new_token.empty? do
          print "> "
          new_token = $stdin.gets.chomp.strip

          if new_token.empty? || !validate_token(new_token)
            puts "Please enter valid token"
            new_token = ""
          end
        end

        new_token
      end

      def fetch_upstream_repo(token)
        return false unless token.is_a?(String) && token =~ TOKEN_REGEX

        url = "#{submission_url}/submissions/resource?token=#{token}"
        uri = URI.parse(url)
        req = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(req)
        end
        Oj.load(res.body)
      rescue => e
        false
      end
    end
  end
end
