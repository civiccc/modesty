class Rudis
  class Structure < Base
    def type
      @options[:type]
    end

    def default_options
      {:type => DefaultType}
    end

    def exists?
      redis.exists(key)
    end
    alias exist? exists?

    def del
      redis.del(key)
    end
    alias delete! del

    def rename(new_key)
      redis.rename(key, self.class.key(new_key))
      @key = new_key
    end

    def redis_type
      redis.type(key)
    end

    def expire(time)
      redis.expire(key, time)
    end

    def expire_at(time)
      redis.expire_at(key, time)
    end

    def ttl
      redis.ttl(key)
    end

    def watch(tries=0)
      return redis.watch(key) unless block_given?

      begin
        redis.watch(key)
        c = 0
        while yield.nil? && (tries==0 || (c+=1) <= tries)
          puts "Optimistic lock failed for #{key}, retrying #{c} time(s)"
        end
      ensure
        redis.unwatch(key)
      end
    end
  end
end

require_local 'structures/counter'
require_local 'structures/list'
require_local 'structures/lock'
require_local 'structures/hash'
require_local 'structures/set'
require_local 'structures/zset'
