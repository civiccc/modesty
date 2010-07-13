module Modesty
  class Experiment
    class Builder
      def method_missing(name, *args)
        if Experiment::ATTRIBUTES.include?(name) && args.count > 0
          val = (args.count == 1) ? args[0] : args
          @exp.instance_variable_set("@#{name}", val)
        else
          @exp.send(name)
        end
      end

      def initialize(exp)
        @exp = exp
      end

      def alternatives(*alts)
        alts.unshift :control unless alts.include? :control
        @exp.instance_variable_set("@alternatives", alts)
      end

      def metrics(*args)
        metrics = args.map do |s|
          Modesty.metrics[s] || raise(
            Modesty::NoMetricError,
            "Undefined metric '#{s.inspect}' in experiment #{@exp}'"
          )
        end
        @exp.instance_variable_set("@metrics", metrics)
      end

      def metric(sym, options={})
        @exp.metrics << (Modesty.metrics[sym] || raise(
          Modesty::NoMetricError,
          "Undefined metric #{sym.inspect} in experiment #{@exp}"
        ))
        if as = options.delete(:as)
          @exp.metric_contexts[sym] = as.to_sym
        end

        raise <<-msg.squish unless options.empty?
          unrecognized options
          #{options.keys.inspect}
        msg
      end
    end
  end
end
