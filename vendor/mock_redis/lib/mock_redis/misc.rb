class MockRedis
  module MiscMethods
    def hash
      @@hash ||= {}
    end

    def del(*keys)
      keys.flatten.each do |key|
        self.hash.delete key
      end
      "OK"
    end

    def exists(key)
      self.hash.has_key?(key)
    end

    def type(key)
      case thing = self.hash[key]
        when nil: "none"
        when String: "string"
        when Array: "list"
        when Set: "set"
        when Hash: "hash"
      end
    end

    def rename(old, new)
      self.hash[new] = self.hash[old]
      self.hash.delete(old)
    end

    def renamenx(old, new)
      rename(old, new) unless exists(new)
    end

    def keys(pattern)
      regexp = Regexp.new(pattern.split("*").map { |r| Regexp.escape(r) }.join(".*"))
      self.hash.keys.select { |key| key =~ regexp }
    end

    def randomkey
      self.hash.keys[rand(dbsize)]
    end

    def dbsize
      self.hash.keys.count
    end

    def flushdb
      self.hash.clear
    end
    alias flushall flushdb

    def multi
      yield if block_given?
    end

    def ping
      "PONG"
    end

    def pipelined
      yield
    end
  end

  include MiscMethods
end
