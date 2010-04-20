class MockRedis
  require 'set'

  module SetMethods
    def sadd(key, value)
      fail_unless_set(key)
      value = value.to_s
      case set = self.hash[key]
        when nil ; self.hash[key] = Set.new([value])
        when Set ; set.add value
      end
    end

    def srem(key, value)
      value = value.to_s
      fail_unless_set(key)
      case set = self.hash[key]
        when nil ; return
        when Set ; set.delete(value)
      end
    end

    def sismember(key, value)
      fail_unless_set(key)
      case set = self.hash[key]
        when nil ; return false ; puts "no set here"
        when Set ; set.include?(value.to_s)
      end
    end

    def spop(key, val)
      fail_unless_set(key)
      case set = self.hash[key]
        when nil ; nil
        when Set
          el = set.to_a[rand(set.size)]
          set.delete el
          el
      end
    end

    def smove(src_key, dst_key, member)
      fail_unless_set(dst_key)
      if el = self.srem(src_key, member)
        self.sadd(dst_key, member)
      end
    end

    def srandmember(key)
      fail_unless_set(key)
      case set = self.hash[key]
        when nil ; nil
        when Set ; set.to_a[rand(set.size)]
      end
    end

    def smembers(key)
      fail_unless_set(key)
      case set = self.hash[key]
      when nil ; []
      when Set ; set.to_a
      end
    end

    def scard(key)
      fail_unless_set(key)
      case set = self.hash[key]
      when nil ; 0
      when Set ; set.size
      end
    end

    def sinter(*keys)
      keys.each { |k| fail_unless_set(k) }
      return Set.new if keys.any? { |k| self.hash[k].nil? }
      keys.inject do |set, key|
        set & self.hash[key]
      end
    end

    def sunion(*keys)
      keys.each { |k| fail_unless_set(k) }
      keys.inject(Set.new) do |set, key|
        return set if self.hash[key].nil?
        set | self.hash[key]
      end
    end

    def sdiff(first, *others)
      [first, *others].each { |k| fail_unless_set(k) }
      others = others.map { |k| self.hash[k] || Set.new }
      others.inject(first) do |memo, set|
        memo - self.hash[set]
      end
    end

    private
    def is_a_set?(key)
      self.hash[key].is_a?(Set) || self.hash[key].nil?
    end

    def fail_unless_set(key)
      fail "Not a set" unless is_a_set?(key)
    end
  end
  
  include SetMethods
end
