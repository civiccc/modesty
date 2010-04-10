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

    class << self
      attr_writer :dir
      def dir
        @dir ||= File.join(
          Modesty::Experiment.dir,
          'metrics'
        )
      end
      
      def load_all!
        Dir.glob(
          File.join(self.dir, '**')
        ).each { |f| load f }
      end

      private
      def data_type(name)
        name_range = (name.to_s + '_range').to_sym
        define_method(name) do |*args|
          start, fin = args
          range = nil
          if start.is_a? Range
            range = start
          elsif !fin.nil?
            range = parse_date(start)..parse_date(fin)
          end

          if range
            begin
              self.data.send(name_range, range)
            rescue NoMethodError
              range.map do |date|
                self.data.send(name, date)
              end
            end
          else
            self.data.send(name, parse_date(start))
          end
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

    def data
      @data ||= (Modesty.data.class)::MetricData.new(self)
    end

    def parse_date(date)
      if date.is_a? Symbol
        Date.send(start)
      elsif date.nil?
        Date.today
      else
        date.to_date
      end
    end

    data_type :count
    data_type :users
    data_type :users_count
    data_type :unidentified_users

    def track!(count=1)
      @parent.track!(count) if @parent
      self.data.track!(count)
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

    #Tracking
    def track!(sym, count=1)
      if @metrics.include? sym
        @metrics[sym].track! count
      else
        raise NoMetricError
      end
    end
  end

  class << self
    include MetricMethods
  end
end
