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
      "#<Modesty::Metric(#{self.slug.inspect})>"
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
      puts start.inspect, fin.inspect unless start.nil? && fin.nil?
      if fin
        parse_date(start)..parse_date(fin)
      elsif start.is_a?(Range)
        parse_date(start.first)..parse_date(start.last)
      else
        parse_date(start)
      end
    end


    [:count, :distribution].each do |data_type|
      data_type_by_range = :"#{data_type}_by_range"
      define_method(data_type) do |*dates|
        date_or_range = parse_date_or_range(*dates)

        case date_or_range
        when Range
          if self.data.respond_to? data_type_by_range
            self.data.send(data_type_by_range, date_or_range)
          else
            date_or_range.map do |date|
              self.data.send(data_type, date)
            end
          end
        when Date, :all
          self.data.send(data_type, date_or_range)
        end
      end
    end

    [:all, :unique, :distribution_by].each do |data_type|
      by_range = :"#{data_type}_by_range"
      define_method(data_type) do |sym, *dates|
        sym = sym.to_sym
        date_or_range = (dates.empty?) ? :all : parse_date_or_range(*dates)
        if date_or_range.is_a? Range
          if self.data.respond_to?(by_range)
            return self.data.send(by_range, sym, date_or_range)
          else
            return date_or_range.map do |date|
              self.data.send(data_type, sym, date)
            end
          end
        elsif date_or_range.is_a?(Date) || date_or_range == :all
          return self.data.send(data_type, sym, date_or_range)
        end
      end
    end

    def track!(count=1, options={})
      if count.is_a? Hash
        options = count
        count = options[:count] || 1
      end

      with = options[:with] || {}
      plural_with = Hash[with.map do |k,v|
        [k.to_s.pluralize.to_sym, v]
      end]

      plural_with[:users] ||= Modesty.identity if Modesty.identity
      self.experiments.each do |exp|
        # only track the for the experiment group if
        # the user has previously hit the experiment
        identity_slug = exp.identity_for(self)
        identity = if identity_slug
          i = plural_with[identity_slug]
          raise IdentityError, """
            #{exp.inspect} requires #{self.inspect} to be tracked
            with #{identity_slug.to_s.singularize.to_sym.inspect}.

            It was tracked :with => #{with.inspect}
          """.squish unless i
          i
        else
          Modesty.identity
        end
        if identity
          alt = exp.data.get_cached_alternative(identity)
          if alt
            (self/(exp.slug/alt)).data.track!(count, plural_with)
          end
        end
      end

      self.data.track!(count, plural_with)
      @parent.track!(count, :with => with) if @parent
    end

    def /(sym)
      Modesty.metrics[@slug/sym] || (raise NoMetricError, "Undefined metric :'#{@slug/sym}'")
    end
  end

  class NoMetricError < NameError; end

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
        raise NoMetricError, "Unrecognized metric #{sym.inspect}"
      end
    end
  end

  class API
    include MetricMethods
  end
end
