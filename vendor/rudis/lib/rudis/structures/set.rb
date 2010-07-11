class Rudis
  class Set < Structure
    def members
      mems = redis.smembers(key)
      mems.map! do |k|
        type.load(k)
      end
      mems
    end
    alias all members
    alias to_a members

    def add(val)
      redis.sadd(key, type.dump(val))
    end
    alias << add

    def is_member?(val)
      redis.sismember(key, type.dump(val))
    end
    alias member? is_member?
    alias include? is_member?

    def card
      redis.scard(key)
    end
    alias count card
    alias size card
    alias length card

    def rem(val)
      redis.srem(key, type.dump(val))
    end
    alias remove rem
    alias delete rem

    def randmember
      e = redis.srandmember(key)
      e && type.load(e)
    end
    alias rand randmember

    def pop
      e = redis.spop(key)
      e && type.load(e)
    end

    def sort(*args)
      #TODO
    end
  end
end
