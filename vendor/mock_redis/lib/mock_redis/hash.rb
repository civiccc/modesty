class MockRedis
  module HashMethods
    def hset(key, hkey, val)
      case h = self.hash[key]
      when nil ; self.hash[key] = {hkey => val.to_s}
      when Hash ; h[hkey] = val.to_s
      else fail "Not a hash"
      end
    end

    def hget(key, hkey)
      case h = self.hash[key]
      when nil ; nil
      when Hash ; h[hkey]
      else fail "Not a hash"
      end
    end

    def hincrby(key, hkey, val)
      case h = self.hash[key]
      when nil ; self.hash[key] = {hkey => val.to_s}
      when Hash ; h[hkey] = (h[hkey].to_i + val).to_s
      else fail "Not a hash"
      end
    end

    def hgetall(key)
      case h = self.hash[key]
      when nil ; {}
      when Hash ; h
      else fail "Not a hash"
      end
    end

    def hkeys(key)
      case h = self.hash[key]
      when nil ; []
      when Hash ; h.keys
      else fail "Not a hash"
      end
    end

    def hvals(key)
      case h = self.hash[key]
      when nil ; []
      when Hash ; h.values
      else fail "Not a hash"
      end
    end

    def hlen(key)
      case h = self.hash[key]
      when nil ; 0
      when Hash ; h.keys.count
      else fail "Not a hash"
      end
    end
  end

  include HashMethods
end
