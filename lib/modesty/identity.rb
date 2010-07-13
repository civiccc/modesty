module Modesty
  #TODO: cookies n stuff
  
  class IdentityError < RuntimeError; end

  module IdentityMethods
    attr_reader :identity

    def identify!(id, opts={})
      unless opts[:ignore]
        raise(
          IdentityError,
          "Identity must be an integer or nil."
        ) unless id.nil? || id.is_a?(Fixnum)

        @identity = id
      end
    end

    def with_identity(id)
      old_identity = Modesty.identity
      Modesty.identify! id
      ret = yield
      Modesty.identify! old_identity
      ret
    end
  end

  class API
    include IdentityMethods
  end
end
