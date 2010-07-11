class Rudis
  class Hash < Structure
    def default_options
      {
        :type => DefaultType,
        :key_type => DefaultType
      }
    end

    def key_type
      @options[:key_type]
    end

    def get(k)
      e = redis.hget(key, key_type.dump(k))
      e && type.load(e)
    end
    alias [] get

    def set(k,v)
      redis.hset(key, key_type.dump(k), type.dump(v))
    end
    alias []= set

    def mget(*ks)
      ks.zip(redis.hmget(key, ks.map { |k|
        key_type.dump(k)
      }).map { |v|
        type.load(v)
      }).to_h 
    end
    alias slice mget

    def mset(hsh)
      hsh = hsh.dup
      hsh.map! {|k,v| [key_type.dump(k), type.dump(v)]}
      redis.hmset(key, *hsh.to_a.flatten)
    end
    alias merge! mset

    def keys
      redis.hkeys(key).map { |k| key_type.load(k) }
    end

    def vals
      redis.hvals(key).map { |v| type.load(v) }
    end
    alias values vals

    def all
      redis.hgetall(key).map! do |k,v|
        [key_type.load(k), type.load(v)]
      end
    end
    alias to_h all

    def len
      redis.hlen(key)
    end
    alias length len
    alias count len
    alias size len

    def empty?
      len == 0
    end

    def del(k)
      redis.hdel(key, key_type.dump(k))
    end

    def has_key?(k)
      redis.hexists(key, key_type.dump(k))
    end
    alias include? has_key?

    def incrby(k, i)
      redis.hincrby(key, key_type.dump(k), i.to_i)
    end

    def incr(k)
      incrby(k, 1)
    end

  end
end
