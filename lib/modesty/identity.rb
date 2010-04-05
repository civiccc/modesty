module Modesty
  #TODO: cookies n stuff

  module IdentityMethods
    attr_reader :identity
    
    def identify(&blk)
      @identifier = blk if blk
    end

    def identify!(*args)
      if @identifier
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
