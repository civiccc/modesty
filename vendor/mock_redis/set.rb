class MockRedis
  module SetMethods
    def sismember(key, value)
      case set = self.hash[key]
      when nil ; false
      when Set ; set.member?(value)
      else fail "Not a set"
      end
    end

    def smembers(key)
      case set = self.hash[key]
      when nil ; []
      when Set ; set.to_a
      else fail "Not a set"
      end
    end

    def sadd(key, value)
      case set = self.hash[key]
      when nil ; self.hash[key] = Set.new([value])
      when Set ; set.add value
      else fail "Not a set"
      end
    end

    def srem(key, value)
      case set = self.hash[key]
      when nil ; return
      when Set ; set.delete value
      else fail "Not a set"
      end
    end

    def scard(key)
      case set = self.hash[key]
      when nil ; 0
      when Set ; set.size
      else fail "Not a set"
      end
    end
  end
  
  include SetMethods
end
