module Modesty
  class Metric
    class Error < StandardError; end
  end

  module MetricMethods
    attr_writer :metrics

    def metrics
      @metrics ||= {}
    end

    def add_metric(metric)
      if self.metrics[metric.slug]
        raise "Metric #{metric.slug.inspect} already defined!"
      end
      self.metrics[metric.slug] = metric
    end

    def new_metric(slug, parent=nil, &block)
      metric = Metric.new(slug, parent)
      yield Metric::Builder.new(metric) if block_given?
      add_metric(metric)
      metric
    end

    #Tracking
    def track!(sym, *args)
      if self.metrics.include? sym
        self.metrics[sym].track! *args
      else
        raise Metric::Error, "Unrecognized metric #{sym.inspect}"
      end
    end
  end

  class API
    include MetricMethods
  end
end

require 'modesty/metric/base'
require 'modesty/metric/builder'
require 'modesty/metric/data'
