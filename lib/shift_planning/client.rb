require "http"
require "json"
require "base64"

module ShiftPlanning
  class Client
    attr_accessor :strict

    def initialize(config = {})
      raise ArgumentError.new('Missing username') unless config.key?(:username)
      @username = config[:username]

      raise ArgumentError.new('Missing password') unless config.key?(:password)
      @password = config[:password]

      raise ArgumentError.new('Missing api key') unless config.key?(:key)
      @key = config[:key]

      @strict = config.key?(:strict) ? config[:strict] : true
      @url = 'http://www.shiftplanning.com/api/'
      @headers = {
        "Content-Type" => "application/x-www-form-urlencoded"
      }
    end

    def authenticated?
      !@token.nil?
    end

    def authenticate
      body = body_formatter({
        "key" => @key,
        "request" => {
          "module" => "staff.login",
          "method" => "GET",
          "username" => @username,
          "password" => @password
        }
      })
      response = HTTP.headers(@headers).post(@url, body)
      @token = JSON.parse(response)["token"]
    end

    def request(method, api_module, request)
      authenticate unless authenticated?

      body = body_formatter({
        "token" => @token,
        "method" => method,
        "module" => api_module,
        "request" => request
      })
      response = HTTP.headers(@headers).post(@url, body)
      result = JSON.parse(response)
      raise ApiError.new(result) if @strict && is_error_response?(result)
      result
    end

    def is_error_response?(response)
      response["status"] != 1
    end

    def body_formatter(body)
      {
        :body => "data=#{JSON.dump(body)}"
      }
    end
  end
end
