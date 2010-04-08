module Modesty
  module DatastoreMethods
    def set_store(type, opts={})
      @store = case type.to_s
      when 'redis'
        require 'modesty/datastore/redis'
        Redis.new(opts)
      when 'mock'
        require 'modesty/datastore/mock_redis'
        MockRedis.new(opts)
      else
        puts "Unrecognized datastore #{type}.  Defaulting to MockRedis."
        self.set_store 'mock'
      end
    end
    alias data= set_store

    def data
      @store ||= set_store 'mock'
    end
  end

  class << self
    include DatastoreMethods
  end
end
