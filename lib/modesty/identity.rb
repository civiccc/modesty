module Modesty
  #TODO: cookies n stuff

  module IdentityMethods
    attr_reader :identity
    
    def identify(id)
      @identity = id
    end
  end

  class << self
    include IdentityMethods
  end
end
