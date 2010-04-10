module Modesty
  class Experiment
    class Stat
      def initialize(exp, blk)
        @blk = blk
        @exp = exp
      end

      def values(dates=nil)
        @values ||= self.fresh_values
      end

      def fresh_values(dates=nil)
        @values = @exp.alternatives.map do |alt|
          tmp_metrics = Modesty.metrics.map do |k, m|
            begin
              [k, m/@exp.slug/alt]
            rescue NoMetricError; [k,m]
            end
          end
          val = @blk.call(Hash[tmp_metrics])
          [alt, val]
        end

        @values = Hash[@values]
      end
    end
  end
end
