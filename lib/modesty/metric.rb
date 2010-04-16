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


    [:count, :distribution].each do |data_type|
      data_type_by_range = :"#{data_type}_by_range"
      define_method(data_type) do |*dates|
        date_or_range = parse_date_or_range(*dates)
        if date_or_range.is_a? Range
          if self.data_respond_to? data_type_by_range
            self.data.send(data_type_by_range, date_or_range)
          else
            date_or_range.map do |date|
              self.data.send(data_type, date)
            end
          end
        elsif date_or_range.is_a? Date
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
        else
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
      with = Hash[with.map do |k,v|
        [k.to_s.pluralize.to_sym, v]
      end]

      if Modesty.identity
        with[:users] ||= Modesty.identity
        self.experiments.each do |exp|
          # only track the for the experiment group if
          # the user has previously hit the experiment
          identity_slug = exp.identity_for(self)
          identity = identity_slug ? with[identity_slug] : Modesty.identity
          raise IdentityError, """
            #TODO
          """.squish unless identity
          alt = exp.data.get_cached_alternative(identity)
          if alt
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
    attr_writer :metrics

    def metrics
      @metrics ||= {}
    end

    def add_metric(metric)
      raise "Metric already defined!" if self.metrics[metric.slug]
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
