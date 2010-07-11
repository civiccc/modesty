class Rudis
  class Counter < Structure
    def incr
      redis.incr(key)
    end

    def decr
      redis.decr(key)
    end

    def incrby(i)
      redis.incrby(key, i.to_i)
    end

    def decrby(i)
      redis.decrby(key, i.to_i)
    end

    def to_i
      redis.get(key).to_i
    end

    def zero?
      to_i.zero?
    end
  end
end
