class Rudis
  module SymbolType
    def self.dump(val)
      val.to_s
    end
    
    def self.load(val)
      val.to_sym
    end
  end
end
