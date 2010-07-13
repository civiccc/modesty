module Modesty
  class Datastore
    class ConnectionError < StandardError; end
    def connected?
      self.ping!
      true
    rescue ConnectionError
      false
    end

    attr_reader :store

    class MetricData
      def initialize(metric)
        @metric = metric
      end
    end

    class ExperimentData
      def initialize(exp)
        @experiment = exp
      end
    end
  end

  module DatastoreMethods
    def set_store(type, opts={})
      @data = case type.to_s
      when 'redis'
        require File.join(Modesty::LIB, 'modesty', 'datastore', 'redis')
        RedisData.new(opts)
      else
        puts "Unrecognized datastore #{type}.  Defaulting to MockRedis."
        self.set_store :redis, :mock => true
      end
    end
    alias data= set_store

    def data
      @data || set_store(:redis, :mock => true)
    end

    def handle_error(e)
      raise e
    end
  end

  class API
    include DatastoreMethods
  end
end
