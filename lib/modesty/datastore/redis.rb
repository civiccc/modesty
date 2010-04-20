module Modesty
  class RedisData < Datastore
    def self.date_key(date)
      "%04d-%02d-%02d" % [date.year, date.month, date.day]
    end

    def initialize(options={})
      if options['mock'] || options[:mock]
        require File.join(
          Modesty::VENDOR, 'mock_redis', 'lib', 'mock_redis.rb'
        )
        @store = MockRedis.new
      else
        $:.unshift(File.join(
          Modesty::VENDOR, 'redis-rb', 'lib'
        ))
        require 'redis'
        $:.shift

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

      def key_for_with(param, *args)
        RedisData.keyify(:metric_with, param, @metric.slug, *args)
      end

      def count(date)
        data.get(self.key(date, 'count')).to_i
      end

      def count_range(range)
        keys = range.map { |d| self.key(d, 'count') }
        data.mget(keys).map(&:to_i?)
      end

      def unidentified_users(date = :all)
        data.get(key_for_with(:users, date, :unidentified)).to_i
      end

      def unidentified_users_range(range)
        keys = range.map { |d| key_for_with(:users, d, :unidentified) }
        data.mget(keys).map(&:to_i?)
      end

      def distribution(date)
        Hash[data.hgetall(self.key(date, :counts)).map do |k,v|
          [k.to_i?, v.to_i]
        end]
      end

      def unique(param, date)
        data.scard(key_for_with(param, date))
      end

      def all(param, date)
        data.smembers(key_for_with(param, date)).map(&:to_i?)
      end

      def distribution_by(param, date)
        ids = data.smembers(key_for_with(param, date)).map(&:to_i?)
        h = {}
        ids.each do |id|
          h[id] = Hash[data.hgetall(key_for_with(param, date, id)).map do |k,v|
            [k.to_i?, v.to_i]
          end]
        end
        return h
      end

      def track!(count, with_args)
        [:all, Date.today].each do |date|
          self.add_counts(date, count)

          self.count_unidentified_user(date) unless with_args[:users]

          with_args.each do |param, id|
            self.add_param_counts(date, count, param, id)
          end
        end
      end

      def add_counts(date, count)
        data.incrby(self.key(date, :count),  count)
        data.hincrby(self.key(date, :counts), count, 1)
      end

      def add_param_counts(date, count, param, id)
        data.sadd(key_for_with(:__keys__), param)
        data.sadd(key_for_with(param, date), id)
        data.hincrby(key_for_with(param, date, id), count, 1)
      end

      def count_unidentified_user(date)
        data.incr(key_for_with(:users, date, :unidentified))
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
        if alt.nil? #return the union
          data.sunion(*@experiment.alternatives.map {|a| self.key(a) })
        else
          data.smembers(self.key(alt))
        end.map(&:to_i)
      end

      def num_users(alt=nil)
        if alt.nil?
          @experiment.alternatives.map do |alt|
            data.scard(self.key(alt)).to_i
          end.sum
        else
          data.scard(self.key(alt)).to_i
        end
      end

    end
  end
end
