module Modesty
  class RedisData < Datastore
    def self.date_key(date)
      "%04d-%02d-%02d" % [date.year, date.month, date.day]
    end

    def initialize(options={})
      if options[:redis]
        @store = options[:redis]
      elsif options['mock'] || options[:mock]
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

    def method_missing(name, *args, &blk)
      @store.send(name, *args, &blk)
    rescue Exception => e
      raise ConnectionError, e.to_s
    end

    def self.keyify(*args)
      args.map {|a| a.to_s}.map do |a|
        (a.is_a?(Date)) ? date_key(a) : a
      end.map do |k|
        k.gsub(/[^\w\-\/]/,'_')
      end.unshift('modesty').join(':')
    end

    class MetricData < Datastore::MetricData
      def key(*args)
        RedisData.keyify('metrics', @metric.slug, *args)
      end

      def data
        Modesty.data
      end

      def key_for_with(*args)
        key(:with, *args)
      end

    # -*- raw counts -*- #
      def count_key(date)
        key(date, :count)
      end

      def add_counts(date, count)
        data.incrby(count_key(date),  count)
      end

      def count(date)
        data.get(count_key(date)).to_i
      end

      def count_range(range)
        keys = range.map { |d| count_key(d) }
        data.mget(keys).map(&:to_i?)
      end

    # -*- unidentified users -*- #
      def count_unidentified_user(date)
        data.incr(unidentified_users_key(date))
      end

      def unidentified_users_key(date)
        key_for_with(:users, date, :unidentified)
      end

      def unidentified_users(date = :all)
        data.get(unidentified_users_key(date)).to_i
      end

      def unidentified_users_range(range)
        keys = range.map { |d| unidentified_users_key(d) }
        data.mget(keys).map(&:to_i?)
      end

    # -*- :with => params -*- #
      def add_param_counts(date, count, param, id)
      #puts "data.hincrby(#{key_for_with(param, date).inspect}, #{id.inspect}, #{count.inspect})"
        data.hincrby(key_for_with(param, date), id, count)
      end

      def unique(param, date)
        data.hlen(key_for_with(param, date))
      end

      def all(param, date)
        data.hkeys(key_for_with(param, date)).map(&:to_i?)
      end

      def distribution_by(param, date)
        dist = data.hvals(key_for_with(param, date)).histogram
        dist.map! { |k,v| [k,v].map(&:to_i?) }
        dist
      end

      def aggregate_by(param, date)
        agg = data.hgetall(key_for_with(param, date))
        agg.map! { |k,v| [k,v].map(&:to_i?) }
        agg
      end

      def track!(count, with_args)
        data.pipelined do
          [:all, Date.today].each do |date|
            self.add_counts(date, count)

            self.count_unidentified_user(date) unless with_args[:user]

            with_args.each do |param, id|
              self.add_param_counts(date, count, param, id)
            end
          end
        end
      end

    end

    class ExperimentData < Datastore::ExperimentData
      def data
        Modesty.data
      end

      def key(*args)
        RedisData.keyify(:experiments, @experiment.slug, *args)
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
