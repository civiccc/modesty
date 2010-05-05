module Modesty
  class Experiment

    def stats
      @stats ||= []
    end

    def reports(*args)
      self.stats.map { |s| s.report(*args) }
    end

    class Builder
      def distribution(metric, options={})
        @exp.stats << DistributionStat.new(@exp, metric, options)
      end

      def conversion(num, denom, options={})
        @exp.stats << ConversionStat.new(@exp, num, denom, options)
      end
    end

    class Stat
      def report(*args)
        return <<-report

          ===#{title}===
          #{significance(*args).inspect}
        report
      end

      def significant?(tolerance=0.01)
        sig = self.significance
        !sig.nil? && sig <= tolerance
      end
    end

    class DistributionStat < Stat
      def initialize(exp, metric_sym, options={})
        @exp = exp
        @metric_sym = metric_sym
      end

      def title
        "Distribution stats on #{@exp.slug.inspect} for #{@metric_sym.inspect}"
      end

      def inspect
        "#<Modesty::Experiment::DistributionStat[ (on #{@exp.slug}) (of #{@metric_sym.inspect}) ]>"
      end

      def data(*args)
        Hash[
          @exp.alternatives.map do |a|
            [a, @exp.metrics(a)[@metric_sym].distribution(*args)]
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
      def initialize(exp, num, denom, options={})
        @exp = exp
        @num_sym = num
        @denom_sym = denom
      end

      def title
        "Count of #{@num_sym} out of #{@denom_sym}"
      end

      def data(*args)
        @exp.alternatives.map do |a|
          num_count = @exp.metrics(a)[@num_sym].count(*args)
          denom_count = @exp.metrics(a)[@denom_sym].count(*args)
          [num_count, denom_count - num_count]
        end
      end

      def inspect
        "#<Modesty::Experiment::ConversionStat[ (on #{@exp.slug}) (of #{@num_sym.inspect})/(#{@denom_sym.inspect}) ]>"
      end

      def significance(*args)
        Significance.significance(*data(*args))
      end
    end
  end
end
