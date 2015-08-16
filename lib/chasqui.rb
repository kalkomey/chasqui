require 'forwardable'
require 'json'
require 'logger'
require 'redis'
require 'redis-namespace'

require "chasqui/version"
require "chasqui/broker"
require "chasqui/subscriber"
require "chasqui/workers/resque_worker"

module Chasqui

  Defaults = {
    inbox_queue: 'inbox',
    redis_namespace: 'chasqui',
    publish_namespace: '__default',
    broker_poll_interval: 3
  }.freeze

  class Config < Struct.new :logger, :namespace, :redis, :inbox_queue, :broker_poll_interval
    def namespace
      self[:namespace] ||= Defaults.fetch(:publish_namespace)
    end

    def inbox_queue
      self[:inbox_queue] ||= Defaults.fetch(:inbox_queue)
    end
    alias inbox inbox_queue

    def redis
      unless self[:redis]
        self.redis = Redis.new
      end

      self[:redis]
    end

    def redis=(redis_config)
      client = case redis_config
      when Redis
        redis_config
      when String
        Redis.new url: redis_config
      else
        Redis.new redis_config
      end

      self[:redis] = Redis::Namespace.new(Defaults.fetch(:redis_namespace), redis: client)
    end

    def logger
      unless self[:logger]
        self.logger = STDOUT
      end

      self[:logger]
    end

    def logger=(new_logger)
      lg = if new_logger.respond_to? :info
        new_logger
      else
        Logger.new(new_logger).tap do |lg|
          lg.level = Logger::INFO
        end
      end

      lg.progname = 'chasqui'
      self[:logger] = lg
    end

    def broker_poll_interval
      self[:broker_poll_interval] ||= Defaults.fetch(:broker_poll_interval)
    end
  end

  module ClassMethods
    extend Forwardable
    def_delegators :config, :redis, :namespace, :inbox, :inbox_queue, :logger

    def configure(&block)
      @config ||= Config.new
      yield @config
    end

    def config
      @config ||= Config.new
    end

    def publish(event, *args)
      payload = { event: event, namespace: namespace, data: args }
      redis.lpush inbox_queue, payload.to_json
    end

    def subscribe(options={}, &block)
      queue = options.fetch :queue
      namespace = options.fetch :namespace

      register_subscriber(queue, namespace).tap do |sub|
        sub.evaluate(&block) if block_given?
        redis.sadd "queues:#{namespace}", queue
      end
    end

    def subscriber(queue)
      subscribers[queue.to_s]
    end

    private

    def register_subscriber(queue, namespace)
      subscribers[queue.to_s] ||= Subscriber.new queue, namespace
    end

    def subscribers
      @subscribers ||= {}
    end
  end

end

Chasqui.extend Chasqui::ClassMethods
