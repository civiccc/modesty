module Modesty
  #TODO: cookies n stuff
  
  class IdentityError < RuntimeError; end

  module IdentityMethods
    attr_reader :identity

    def identify!(id, opts={})
      @identity = id unless opts[:ignore]
    end

    def with_identity(id)
      old_identity = Modesty.identity
      Modesty.identify! id
      yield
      Modesty.identify! old_identity
    end
  end

  class << self
    include IdentityMethods
  end
end
