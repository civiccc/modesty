module Modesty
  class Experiment

    def stats
      @stats ||= Hash.new do |hash, key|
        raise Error, <<-msg.squish
          Unrecognized stat #{key.inspect}
        msg
      end
    end

    def reports(*args)
      self.stats.values.map { |s| s.report(*args) }
    end

    def aggregates(metric, *args)
      metric = metric.slug if metric.is_a? Metric
      context = self.identity_for(metric) || :users
      self.alternatives.hashmap do |a|
        agg = self.metrics(a)[metric].aggregate_by(context, *args)
        agg = agg.sum if agg.is_a?(Array)
        self.users(a).hashmap { 0 }.merge!(agg)
      end
    end

    def distributions(metric, *args)
      aggregates(metric, *args).map_values! do |agg|
        agg.values.histogram
      end
    end

    def dist_analysis(metric, *args)
      Significance.dist_significance(
        distributions(metric, *args)
      )
    end

    class Builder
      def distribution(name, options={}, &blk)
        @exp.stats[name] = DistributionStat.new(@exp, name, options, &blk)
      end

      def conversion(name, options={}, &blk)
        @exp.stats[name] = ConversionStat.new(@exp, name, options, &blk)
      end
    end

    class ArgumentProxy
      def initialize(obj, *args)
        @obj = obj
        @args = args
      end

      def inspect
        "#<ArgumentProxy[ #{@obj.inspect} ]>"
      end

      def method_missing(meth, *args)
        data = @obj.send(meth, *(args + @args))
        # [Jay] #TODO: Hack alert!
        # this doesn't take into account Metric#all,
        # which returns an Array for either a date range
        # or a single day
        data = data.sum if data.is_a?(Array)
        data
      end
    end

    class Stat
      def initialize(exp, name, options={}, &blk)
        @exp = exp
        @name = name
        @get_data = blk || default_get_data(options[:on])
      end

      def title
        @name.to_s.split(/_/).map(&:capitalize).join(' ')
      end

      def report(*args)
        sig = significance(*args)
        sig = "not significant" if sig.nil?
        return <<-report

          === #{title} ===
          #{analysis(*args).inspect}
          Significance: #{sig}
        report
      end

      def significant?(tolerance=0.01)
        sig = self.significance
        !sig.nil? && sig <= tolerance
      end

      private
      def argument_proxy_hash(hsh, *args)
        Hash[
          hsh.map do |k, v|
            [k, ArgumentProxy.new(v, *args)]
          end
        ]
      end

      def data_for(alt, *args)
        data = @get_data.call(argument_proxy_hash(@exp.metrics(alt), *args))
      end
    end

    class DistributionStat < Stat
      def default_get_data(on_param)
        lambda do |metrics|
          metrics[on_param].distribution
        end
      end

      def inspect
        "#<Modesty::Experiment::DistributionStat[ (on #{@exp.slug}) (of #{@metric_sym.inspect}) ]>"
      end

      def data(*args)
        Hash[
          @exp.alternatives.map do |a|
            [a, data_for(a, *args)]
          end
        ]
      end

      def analysis(*args)
        Significance.dist_significance(data(*args))
      end

      def significance(*args)
        analysis(*args)[:significant]
      end

    end

    class ConversionStat < Stat
      def default_get_data(on_param)
        lambda do |metrics|
          num_count = metrics[on_param[0]].count
          denom_count = metrics[on_param[1]].count
          [num_count, denom_count - num_count]
        end
      end

      def analysis(*args)
        Hash[
          @exp.alternatives.map do |a|
            [a, data_for(a, *args)]
          end
        ]
      end

      def data(*args)
        analysis.values
      end

      def inspect
        "#<Modesty::Experiment::ConversionStat[ #{@name} ]>"
      end

      def significance(*args)
        Significance.significance(*data(*args))
      end
    end
  end
end
