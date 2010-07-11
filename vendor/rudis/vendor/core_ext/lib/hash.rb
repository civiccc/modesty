class Hash
  def rmerge!(hsh)
    hsh.each do |k,v|
      self[k] = v unless self.has_key? k
    end
    self
  end

  def rmerge(hsh)
    self.dup.rmerge!(hsh)
  end

  def accept_options!(hsh)
    opts_diff = self.keys - hash.keys
    raise ArgumentError <<-msg.squish unless opts_diff.empty?
      Unrecognized options #{opts_diff.inspect}
    msg
    options.rmerge!(hsh)
  end

  def accept_options(hsh)
    self.dup.accept_options!(hsh)
  end

  def map_keys!
    keys.each do |k|
      self[yield(k)] = self.delete(k)
    end
    self
  end

  def map_values!
    self.each do |k,v|
      self[k] = v
    end
    self
  end

  def map!
    self.keys.each do |k|
      new_k, new_v = yield(k, self.delete(k))
      self[new_k] = new_v
    end
    self
  end
end
