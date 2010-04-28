class Symbol
  unless method_defined? :/
    def /(other)
      :"#{self}/#{other}"
    end
  end

  def inspect
    self.to_s.split(/\//).map { |s| ":#{s}"}.join('/')
  end

  def <=>(other)
    self.to_s <=> other.to_s
  end
end
