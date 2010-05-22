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
end
