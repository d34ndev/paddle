# frozen_string_literal: true

module Paddle
  class Configuration
    attr_reader :environment
    attr_reader :api_key

    attr_accessor :version
    attr_accessor :connection_options

    def initialize
      @environment = :production
      @environment_set = false
      @version ||= 1
      @connection_options = {}
    end

    # When the environment isn't set, it's detected from the API key
    def environment=(env)
      if env.nil?
        @environment_set = false
        @environment = key_environment || :production
        return
      end

      env = env.to_sym
      unless [ :development, :sandbox, :production ].include?(env)
        raise ArgumentError, "#{env.inspect} is not a valid environment"
      end

      check_key_matches!(env)
      @environment = env
      @environment_set = true
    end

    def api_key=(key)
      @api_key = key

      if @environment_set
        check_key_matches!(@environment)
      else
        @environment = key_environment || :production
      end
    end

    MERGEABLE = [ :api_key, :environment, :version, :connection_options ].freeze

    # Returns a new Configuration with the given options applied over this one. When a new
    # API key is given without an environment, the environment is detected from the key,
    # or kept from this config for older keys without a prefix
    def merge(**options)
      unknown = options.keys - MERGEABLE
      raise ArgumentError, "Unknown config options: #{unknown.join(", ")}" if unknown.any?

      config = Configuration.new
      config.version = options.fetch(:version, version)
      config.connection_options = options.fetch(:connection_options, connection_options)
      config.api_key = options.fetch(:api_key, api_key)

      if options.key?(:environment)
        config.environment = options[:environment]
      elsif !options.key?(:api_key) || config.key_environment.nil?
        config.environment = environment
      end

      config
    end

    def url
      case @environment
      when :production
        "https://api.paddle.com"
      when :development, :sandbox
        "https://sandbox-api.paddle.com"
      end
    end

    protected

    # API keys created since May 2025 start with pdl_live_ or pdl_sdbx_. Older keys have no prefix
    def key_environment
      case @api_key
      when /\Apdl_live_/ then :production
      when /\Apdl_sdbx_/ then :sandbox
      end
    end

    private

    def check_key_matches!(env)
      key_env = key_environment
      return if key_env.nil? || (key_env == :production) == (env == :production)

      raise ArgumentError, "The API key is for the #{key_env} environment, but environment is set to #{env.inspect}"
    end
  end
end
