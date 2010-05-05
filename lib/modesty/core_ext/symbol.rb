class Symbol
  unless method_defined? :/
    def /(other)
      :"#{self}/#{other}"
    end
  end

  alias __old_inspect inspect
  def inspect
    s = self.to_s

    #some things should not use this.
    if (
      s[0..0] == '/' ||
      s[-1..-1] == '/' ||
      s.include?("//") ||
      s.include?(":")
    )
      return self.__old_inspect
    end

    begin
      inspected = self.to_s.split(/\//).map { |s| ":#{s}"}.join('/')
      return inspected
    rescue
      return self.__old_inspect
    end
  end

  def <=>(other)
    self.to_s <=> other.to_s
  end
end
