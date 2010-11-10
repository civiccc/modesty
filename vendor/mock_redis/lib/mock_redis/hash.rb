class MockRedis
  module HashMethods
    def hset(key, hkey, val)
      case h = self.hash[key]
      when nil then self.hash[key] = {hkey => val.to_s}
      when Hash then h[hkey] = val.to_s
      else fail "Not a hash"
      end
    end

    def hget(key, hkey)
      case h = self.hash[key]
      when nil then nil
      when Hash then h[hkey]
      else fail "Not a hash"
      end
    end

    def hincrby(key, hkey, val)
      case h = self.hash[key]
      when nil then self.hash[key] = {hkey => val.to_s}
      when Hash then h[hkey] = (h[hkey].to_i + val).to_s
      else fail "Not a hash"
      end
    end

    def hgetall(key)
      case h = self.hash[key]
      when nil then {}
      when Hash then h
      else fail "Not a hash"
      end
    end

    def hkeys(key)
      case h = self.hash[key]
      when nil then []
      when Hash then h.keys
      else fail "Not a hash"
      end
    end

    def hvals(key)
      case h = self.hash[key]
      when nil then []
      when Hash then h.values
      else fail "Not a hash"
      end
    end

    def hlen(key)
      case h = self.hash[key]
      when nil then 0
      when Hash then h.keys.count
      else fail "Not a hash"
      end
    end
  end

  include HashMethods
end
