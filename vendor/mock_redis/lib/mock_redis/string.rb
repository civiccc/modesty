class MockRedis
  module StringMethods
    def [](key)
      self.hash[key]
    end
    alias get []

    def []=(key, value)
      self.hash[key] = value.to_s
    end
    alias set []=

    def setnx(key, value)
      self.hash[key] = value.to_s unless self.hash.has_key?(key)
    end

    def incr(key)
      self.hash[key] = (self.hash[key].to_i + 1).to_s
    end

    def incrby(key, value)
      self.hash[key] = (self.hash[key].to_i + value).to_s
    end

    def mget(keys)
      self.hash.values_at(*keys)
    end

  end

  include StringMethods
end
