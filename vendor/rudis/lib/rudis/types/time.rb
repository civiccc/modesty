class Rudis
  module TimeType
    def self.dump(val)
      val.to_i
    end

    def self.load(val)
      Time.at(val.to_i)
    end
  end
end
