require File.join(
  Modesty::ROOT,
  '../vendor/redis-rb/lib/redis.rb'
) unless defined? Redis

module Modesty
  class RedisData < Datastore
    def self.date_key(date)
      "%04d-%02d-%02d" % [date.year, date.month, date.day]
    end

    def initialize(options={})
      if options['mock'] || options[:mock]
        require File.join(
          Modesty::ROOT, '../vendor/mock_redis.rb'
        )
        @store = MockRedis.new
      else
        require File.join(
          Modesty::ROOT, '../vendor/redis-rb/lib/redis' 
        )
        @store = Redis.new(options)
      end
    end

    def ping!
      self.ping
    end

    def method_missing(name, *args)
      @store.send(name, *args)
    rescue Errno::ECONNREFUSED
      raise ConnectionError
    end

    def self.keyify(*args)
      args.map {|a| a.to_s}.map do |a|
        (a.is_a?(Date)) ? date_key(a) : a
      end.map do |k|
        k.gsub(/[^\w\-]/,'_')
      end.unshift('modesty').join(':')
    end

    class MetricData < Datastore::MetricData
      def key(*args)
        RedisData.keyify('metrics', @metric.slug, *args)
      end

      def data
        Modesty.data
      end

      def with_key(param, *args)
        RedisData.keyify(:metric_with, param, @metric.slug, *args)
      end

      def count(date)
        data.get(self.key(date, 'count')).to_i
      end

      def count_range(range)
        keys = range.map { |d| self.key(d, 'count') }
        data.mget(keys).map { |s| s.to_i }
      end

      def unidentified_users(date)
        data.get(with_key(:users, date, :unidentified))
      end

      def unidentified_users_range(range)
        keys = range.map { |d| with_key(:users, d, :unidentified) }
        data.mget(keys)
      end

      def unique(param, date)
        data.scard(with_key(param, date))
      end

      def all(param, date)
        data.smembers(with_key(param, date))
      end

      def track!(count, with)
        data.incrby(self.key(Date.today, 'count'), count)
        data.hincrby(self.key('counts'), count, 1)

        if !with[:users]
          data.incr(with_key(:users, Date.today, 'unidentified'))
        end

        with.each do |param, id|
          data.sadd(with_key(param, Date.today), id)
          data.sadd(with_key(param, :all), id)
        end
      end
    end

    class ExperimentData < Datastore::ExperimentData
      def data
        Modesty.data
      end

      def key(*args)
        ([
          'modesty:experiments',
          @experiment.slug.to_s.gsub(/\//,':')
        ] + args.map { |a| a.to_s }).join(':')
      end

      def register!(alt, identity)
        #puts "Registering #{identity.inspect} in experiment group :#{@experiment.slug}/#{alt.inspect}"
        old_alt = self.get_cached_alternative(identity)
        if old_alt
          data.srem(self.key(old_alt), identity)
        end
        data.sadd(self.key(alt), identity)
        return alt
      end

      def get_cached_alternative(identity)
        @experiment.alternatives.each do |alt|
          if data.sismember(self.key(alt), identity)
            return alt
          end
        end
        return nil
      end

      def users(alt=nil)
        if alt.nil? #return the sum
          @experiment.alternatives.map do |alt|
            data.smembers(self.key(alt))
          end.inject([]){|s,i|s+i}
        else
          data.smembers(self.key(alt))
        end
      end

      def num_users(alt=nil)
        if alt.nil?
          @experiment.alternatives.map do |alt|
            data.scard(self.key(alt)).to_i
          end.inject(0){|s,i|s+i}
        else
          data.scard(self.key(alt)).to_i
        end
      end

    end
  end
end

#require File.join(
#  File.dirname(__FILE__),
#  'key_value_methods'
#)
