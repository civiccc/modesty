module Modesty
  #TODO: cookies n stuff
  
  class IdentityError < RuntimeError; end

  module IdentityMethods
    attr_reader :identity
    
    def identify(sym=nil, &blk)
      @identifier = nil if sym == :default
      @identifier = blk if blk
    end

    def identify!(*args)
      if @identifier
        if @identifier.arity >= 0 && @identifier.arity != args.count
          raise ArgumentError, "Wrong number of arguments (#{args.count} for #{@identifier.arity})"
        end
        @identity = @identifier.call(*args)
      elsif args[0].is_a? Fixnum
        @identity = args[0]
      end
    end
  end

  class << self
    include IdentityMethods
  end
end
