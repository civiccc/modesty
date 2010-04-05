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

      def hook(&blk)
        Modesty.hook do |metric, count|
          blk.call(count) if metric == @metric
        end
      end
    end

    ATTRIBUTES = [
      :description
    ]
    attr_reader *ATTRIBUTES
    attr_reader :slug
    attr_reader :parent
    
    #doctest: I can make a metric!
    # >> m = Modesty::Metric.new :foo
    # >> m.slug
    # => :foo
    def initialize(slug, parent=nil)
      @slug = slug
      @parent = parent
    end

    def redis_key
      "modesty:metrics:#{@slug.to_s.gsub(/\//,':')}"
    end

    def total
      Modesty.redis[self.redis_key]
    end

    def track!(count = 1)
      Modesty.redis.incrby(self.redis_key, count)
      @parent.track!(count) if @parent
    end
  end

  class NoMetricError < NameError; end

  module MetricMethods
    attr_accessor :metrics

    #doctest: tools for adding new metrics
    # >> m = Modesty.new_metric(:foo) { |m| m.description "Foo" }
    # >> m.class
    # => Modesty::Metric
    # >> m.description
    # => "Foo"
    # >> Modesty.metrics.include? m
    # => true
    #
    #doctest: I can even call it without a block!
    # >> m = Modesty.new_metric :baz
    # >> m.slug
    # => :baz
    def add_metric(metric)
      @metrics ||= {}
      raise "Metric already defined!" if @metrics[metric.slug]
      @metrics[metric.slug] = metric
    end

    def new_metric(slug, parent=nil, &block)
      metric = Metric.new(slug, parent)
      yield Metric::Builder.new(metric) if block
      add_metric(metric)
      metric
    end

    #Redis
    def redis
      @redis ||= self::MockRedis.new
    end

    #Hooks
    def hook(&block)
      (@hooks ||= []) << block
    end

    def run_hooks(metric, count)
      @hooks ||= []
      @hooks.each do |hook|
        hook.call(metric,count)
      end
    end

    #Tracking
    def track!(sym, count=1)
      if @metrics.include? sym
        @metrics[sym].track! count
        self.run_hooks(@metrics[sym], count)
      else
        raise NoMetricError
      end
    end
  end

  class << self
    include MetricMethods
  end
end
