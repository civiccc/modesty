
class Rudis
  module JSONType

    def self.dump(val)
      require 'rubygems'
      require 'json'
      val.to_json
    end

    def self.load(val)
      require 'rubygems'
      require 'json'
      JSON.load(val)
    end
  end
end
