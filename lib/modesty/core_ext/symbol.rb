class Symbol
  unless method_defined? :/
    def /(other)
      :"#{self}/#{other}"
    end
  end
end
