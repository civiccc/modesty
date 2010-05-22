class Array
  unless method_defined? :histogram
    def histogram
      hsh = {}
      self.each do |e|
        hsh[e] ||= 0
        hsh[e] += 1
      end
      hsh
    end
  end
end
