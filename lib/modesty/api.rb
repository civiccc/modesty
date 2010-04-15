module Modesty
  class API
  end

  class << self
    def api
      @api ||= API.new
    end

    def method_missing(meth, *args, &blk)
      self.api.send(meth, *args, &blk)
    end
  end
end
