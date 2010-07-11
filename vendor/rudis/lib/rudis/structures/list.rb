class Rudis
  class List < Structure
    def len
      redis.llen(key)
    end
    alias length len
    alias size len
    alias count len

    def empty?
      len == 0
    end

    def index(i)
      type.load(redis.lindex(key, i.to_i))
    end

    def range(range)
      redis.lrange(key, range.first.to_i, range.last.to_i).map do |e|
        type.load(e)
      end
    end

    def all
      range 0..-1
    end
    alias to_a all

    def [](thing)
      if thing.is_a? Fixnum
        index thing
      elsif thing.is_a? Range
        range thing
      end
    end

    def set(i, val)
      redis.lset(key, i.to_i, type.dump(val))
    end
    alias []= set

    def rpush(val)
      redis.rpush(key, type.dump(val))
    end
    alias push rpush
    alias << rpush

    def rpop
      e = redis.rpop(key)
      e && type.load(e)
    end
    alias pop rpop

    def lpush(val)
      redis.lpush(key, type.dump(val))
    end
    alias unshift lpush
    alias >> lpush

    def lpop
      e = redis.lpop(key)
      e && type.load(e)
    end
    alias shift lpop

    def trim(range)
      redis.trim(key, range.first.to_i, range.last.to_i)
    end
    alias trim! trim
  end
end
