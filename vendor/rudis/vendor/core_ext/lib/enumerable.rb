module Enumerable
  def to_set
    require 'set'
    Set.new(self)
  end

  # assumes a collection of k-v pairs
  def to_h
    Hash[self]
  end

  def histogram
    hist = Hash.new(0)
    self.each do |e|
      hist[e] += 1
    end
    hist
  end

  def hashmap
    map { [self, yield(self)] }.to_h
  end
end
