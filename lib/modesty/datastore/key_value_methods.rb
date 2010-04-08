require 'date'

module Modesty
  class Metric
    def key(*args)
      ([
        'modesty:metrics',
        @slug.to_s.gsub(/\//,':'),
      ] + args.map { |a| a.to_s }).join(':')
    end

    def values(start=nil, fin=nil)
      if fin.nil?
        if start.is_a? Symbol
          start = Date.send(start)
        elsif start.nil?
          start = Date.today
        else
          start = start.to_date
        end
        return Modesty.data.get(self.key(start, 'count')).to_i
      else
        keys = (start.to_date..fin.to_date).map { |d| self.key(d, 'count') }
        return Modesty.data.mget(keys).map { |s| s.to_i }
      end
    end

    def track!(count = 1)
      @parent.track!(count) if @parent
      Modesty.data.incrby(self.key(Date.today, 'count'), count)
    end
  end

  class Experiment
    def key(*args)
      ([
        'modesty:experiments',
        @slug.to_s.gsub(/\//,':')
      ] + args.map { |a| a.to_s }).join(':')
    end

    def register!(alt=nil)
      alt ||= self.ab_test
      old_alt = self.get_cached_alternative
      if old_alt
        Modesty.data.srem(self.key(old_alt), Modesty.identity)
      end
      Modesty.data.sadd(self.key(alt), Modesty.identity)
      return alt
    end

    def get_cached_alternative(identity=nil)
      identity ||= Modesty.identity
      self.alternatives.each do |alt|
        if Modesty.data.sismember(self.key(alt), identity)
          return alt
        end
      end
      return nil
    end

    def users(alt=nil)
      if alt.nil? #return the sum
        self.alternatives.map do |alt|
          Modesty.data.scard(self.key(alt)).to_i
        end.inject(0){|s,i|s+i}
      else
        Modesty.data.scard(self.key(alt)).to_i
      end
    end

  end

  class ConnectionError < StandardError; end

  class << self
    def ping!
      self.data.ping
    rescue Errno::ECONNREFUSED
      raise self::ConnectionError
    end

    def connected?
      self.ping!
      true
    rescue
      false
    end
  end
end
