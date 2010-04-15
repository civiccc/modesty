class MockRedis
  module MiscMethods
    def del(*keys)
      keys.flatten.each do |key|
        self.hash.delete key
      end
      "OK"
    end

    def exists(key)
      self.hash.has_key?(key)
    end

    def keys(pattern)
      regexp = Regexp.new(pattern.split("*").map { |r| Regexp.escape(r) }.join(".*"))
      self.hash.keys.select { |key| key =~ regexp }
    end

    def flushdb
      self.hash.clear
    end

    def ping
      "PONG"
    end
  end

  include MiscMethods
end
