class Hash
  # addition for histogram aggregation
  # >> {:a=>1, :b=>2} + {:a=>3, :c=>4}
  # => {:a=>4, :b=>2, :c=>4}
  def +(other)
    hash = self.dup
    other.each do |k, v|
      if hash.include? k
        hash[k] += v
      else
        hash[k] = v
      end
    end
    hash
  end

  def map_values!(&blk)
    self.each do |k,v|
      self[k] = yield(v)
    end
  end

  def map_values(&blk)
    self.dup.map_values!(&blk)
  end
end
