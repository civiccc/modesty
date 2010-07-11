class Rudis
  module IntegerType
    def self.dump(val)
      val.to_s
    end

    def self.load(val)
      val.to_i
    end
  end
end
