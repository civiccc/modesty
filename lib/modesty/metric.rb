module Modesty
  class Metric
    attr_reader :slug
    
    #doctest: I can make a metric!
    # >> m = Modesty::Metric.new :foo
    # >> m.slug
    # => :foo
    def initialize(slug)
      @slug = slug
    end
  end

  class NoMetricError < NameError; end

  class << self

    attr_accessor :metrics

    #doctest: tools for adding new metrics
    # >> m = Modesty.new_metric(:foo) { |m| m.instance_variable_set("@foo", :bar) }
    # >> m.class
    # => Modesty::Metric
    # >> m.instance_variable_get "@foo"
    # => :bar
    # >> Modesty.metrics.include? m
    # => true
    #
    #doctest: I can even call it without a block!
    # >> m = Modesty.new_metric :baz
    # >> m.slug
    # => :baz
    def add_metric(metric)
      @metrics ||= []
      @metrics << metric
    end

    def new_metric(slug, &block)
      metric = Metric.new slug
      yield metric if block
      add_metric(metric)
      metric
    end
  end
end
