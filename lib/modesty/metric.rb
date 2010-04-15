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
      private
      def data_type(name)
        name_range = (name.to_s + '_range').to_sym
        define_method(name) do |*args|
          date_or_range = parse_date_or_range(*args[0..1])
          if date_or_range.is_a? Range
            begin
              self.data.send(name_range, date_or_range)
            rescue NoMethodError
              date_or_range.map do |date|
                self.data.send(name, date)
              end
            end
          elsif date_or_range.is_a? Date
            self.data.send(name, date_or_range)
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

    # metrics should know what experiments use them,
    # to enable smart tracking.
    def experiments
      @experiments ||= []
    end

    def initialize(slug, parent=nil)
      @slug = slug
      @parent = parent
    end

    def data
      @data ||= (Modesty.data.class)::MetricData.new(self)
    end

    def parse_date(date)
      if date.is_a? Symbol
        return date if date == :all
        Date.send(date)
      elsif date.nil?
        Date.today
      else
        date.to_date
      end
    end

    def parse_date_or_range(start=nil,fin=nil)
      if fin.nil?
        parse_date(start)
      else
        parse_date(start)..parse_date(fin)
      end
    end

    data_type :count
    data_type :unidentified_users

    def get_by(all_or_unique, sym, start=nil, fin=nil)
      sym = sym.to_sym
      by_range = :"#{all_or_unique}_by_range"
      date_or_range = (start.nil?) ? :all : parse_date_or_range(start, fin)
      if date_or_range.is_a? Range
        if self.data.respond_to?(by_range)
          return self.data.send(by_range, sym, date_or_range)
        else
          return date_or_range.map do |date|
            self.data.send(all_or_unique, sym, date)
          end
        end
      else
        return self.data.send(all_or_unique, sym, date_or_range)
      end
    end

    def all(*args)
      self.get_by(:all, *args)
    end

    def unique(*args)
      self.get_by(:unique, *args)
    end

    def track!(count=1, options={})
      if count.is_a? Hash
        options = count
        count = options[:count] || 1
      end

      with = options[:with] || {}
      with = Hash[with.map do |k,v|
        [k.to_s.pluralize.to_sym, v]
      end]

      if Modesty.identity
        with[:users] ||= Modesty.identity
        self.experiments.each do |exp|
          # only track the for the experiment group if
          # the user has previously hit the experiment
          if (alt = exp.data.get_cached_alternative(Modesty.identity))
            (self/(exp.slug/alt)).data.track!(count, with)
          end
        end
      end

      self.data.track!(count, with)
      @parent.track!(count, with) if @parent
    end

    def /(sym)
      Modesty.metrics[@slug/sym] || (raise NoMetricError, "Undefined metric :'#{@slug/sym}'")
    end
  end

  class NoMetricError < NameError; end

  module MetricMethods
    attr_accessor :metrics

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
    def track!(sym, *args)
      if @metrics.include? sym
        @metrics[sym].track! *args
      else
        raise NoMetricError, "Unrecognized metric #{sym.inspect}"
      end
    end
  end

  class << self
    include MetricMethods
  end
end
