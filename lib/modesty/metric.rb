module Modesty
  class Metric
    class Error < StandardError; end
  end

  module MetricMethods
    attr_writer :metrics

    def metrics
      @metrics ||= Hash.new do |h, k|
        raise Metric::Error, <<-msg.squish
          Unrecognized metric #{k.inspect}
        msg
      end
    end

    def add_metric(metric)
      raise Metric::Error <<-msg if self.metrics.include? metric.slug
        Metric #{metric.slug.inspect} already defined!
      msg
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
      self.metrics[sym].track! *args
    end
  end

  class API
    include MetricMethods
  end
end

require 'modesty/metric/base'
require 'modesty/metric/builder'
require 'modesty/metric/data'
