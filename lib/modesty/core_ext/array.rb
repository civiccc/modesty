class Array
  unless method_defined? :histogram
    def histogram
      hsh = Hash.new(0)
      self.each do |e|
        hsh[e] += 1
      end
      hsh
    end
  end

  def to_h
    Hash[self]
  end
  
  def hashmap
    self.map do |e|
      [e, yield(e)]
    end.to_h
  end
end
