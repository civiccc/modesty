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

    def register!
      Modesty.data.sadd(
        self.key(self.ab_test),
        Modesty.identity
      )
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
end
