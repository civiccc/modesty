module Modesty
  class Metric
    class Builder

      def method_missing(name, *args)
        if Metric::ATTRIBUTES.include? name
          @metric.instance_variable_set("@#{name}", args[0])
        else
          super
        end
      end

      def initialize(metric)
        @metric = metric
      end

      def submetric(slug, &blk)
        Modesty.new_metric(@metric.slug/slug, @metric, &blk)
      end

    end
  end
end
