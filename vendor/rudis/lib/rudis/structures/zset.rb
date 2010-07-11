class Rudis
  class ZSet < Structure
    def default_options
      {
        :type => DefaultType,
        :score_type => IntegerType
      }
    end

    def score_type
      @options[:score_type]
    end

    def add(member, score=1)
      redis.zadd(key, score_type.dump(score), type.dump(member))
    end
    alias << add

    def rem(member)
      redis.zrem(key, type.dump(member))
    end

    def incrby(member, i)
      redis.zincrby(key, i.to_i, member)
    end

    def incr(member)
      incrby(member, 1)
    end

    def rank(member)
      i = redis.zrank(key, member)
      i && i.to_i
    end

    def card
      redis.zcard(key)
    end
    alias size card
    alias length card
    alias count card

    def empty?
      card == 0
    end

    def range(ran)
      redis.zrange(key, ran.first.to_i, ran.last.to_i).map do |e|
        type.load(e)
      end
    end

    def revrange(ran)
      redis.zrevrange(key, ran.first.to_i, ran.last.to_i).map do |e|
        type.load(e)
      end
    end
    alias rev_range revrange

    def rangebyscore(min, max)
      redis.zrangebyscore(key,
        score_type.dump(min),
        score_type.dump(max)
      ).map do |e|
        type.load(e)
      end
    end
    alias range_by_score rangebyscore

    def [](val)
      if val.is_a? Range
        range(val)
      else
        self[val..val]
      end
    end
    alias slice []

    def all
      range(0..-1)
    end
    alias to_a all

    def first
      self[0..0].first
    end

    def last
      self[-1..-1].first
    end

    def score(member)
      s = redis.zscore(key, type.dump(member))
      s && score_type.load(s)
    end

    def member?(val)
      !score(val).nil?
    end
    alias include? member?

  end
end
