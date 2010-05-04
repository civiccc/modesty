module Modesty
  class Metric

    class << self
      private
      def data_type(name)
      end
    end

    ATTRIBUTES = [
      :description
    ]
    attr_reader *ATTRIBUTES
    attr_reader :slug
    attr_reader :parent

    # metrics should know what experiments use them,
    # to enable smart tracking.
    def experiments
      @experiments ||= []
    end

    def initialize(slug, parent=nil)
      @slug = slug
      @parent = parent
    end

    def inspect
      "#<Modesty::Metric[ #{self.slug.inspect} ]>"
    end

    def /(sym)
      Modesty.metrics[@slug/sym] || (raise NoMetricError, "Undefined metric :'#{@slug/sym}'")
    end
  end
end
