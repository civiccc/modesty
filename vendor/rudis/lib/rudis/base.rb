class Rudis
  class << self
    attr_writer :redis
    def redis
      @redis ||= begin
        require 'rubygems'
        require 'redis'
        Redis.new
      end
    end

    attr_writer :key_base
    def key_base
      @key_base ||= ['rudis']
    end

    attr_writer :key_sep
    def key_sep
      @key_sep ||= ':'
    end

    def key(*args)
      ([key_base].flatten + args).join(key_sep)
    end
  end


  class Base < Rudis
    class << self
      attr_writer :redis
      def self.redis
        @redis ||= super
      end
    end

    def redis
      @redis ||= self.class.redis
    end

    def initialize(key, options={})
      @key = key
      @options = options
      @options.rmerge!(default_options)
    end

    def default_options
      {}
    end

    def key(*args)
      self.class.key(@key, *args)
    end
  end
end
