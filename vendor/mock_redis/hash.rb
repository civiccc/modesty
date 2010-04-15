class MockRedis
  module HashMethods
    def hset(key, hkey, val)
      case hash = self.hash[key]
      when nil ; self.hash[key] = {hkey => val.to_s}
      when Hash ; self.hash[key][hkey] = val.to_s
      else fail "Not a hash"
      end
    end

    def hget(key, hkey)
      case hash = self.hash[key]
      when nil ; nil
      when Hash ; hash[hkey]
      else fail "Not a hash"
      end
    end

    def hincrby(key, hkey, val)
      case hash = self.hash[key]
      when nil ; self.hash[key] = {hkey => val.to_s}
      when Hash ; self.hash[key][hkey] = (self.hash[key][hkey].to_i + val).to_s
      else fail "Not a hash"
      end
    end

    def hdecrby(key, hkey, val)
      case hash = self.hash[key]
      when nil ; self.hash[key] = {hkey => val.to_s}
      when Hash ; hash[hkey] = (hash[hkey].to_i - val).to_s
      else fail "Not a hash"
      end
    end

    def hgetall(key)
      case hash = self.hash[key]
      when nil ; {}
      when Hash ; hash
      else fail "Not a hash"
      end
    end

    def hkeys(key)
      case hash = self.hash[key]
      when nil ; []
      when Hash ; hash.keys
      else fail "Not a hash"
      end
    end

    def hlen(key)
      case hash = self.hash[key]
      when nil ; 0
      when Hash ; hash.keys.count
      else fail "Not a hash"
      end
    end
  end

  include HashMethods
end
