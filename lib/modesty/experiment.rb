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

      def metrics(*args)
        @exp.instance_variable_set("@metrics", args.map { |s| Modesty.metrics[s] })
      end
    end

    def initialize(slug)
      @slug = slug
    end

    ATTRIBUTES = [
      :description,
      :alternatives,
    ]

    attr_reader *ATTRIBUTES 
    attr_reader :slug
    attr_reader :metrics

    def ab_test
      @alternatives[Modesty.identity % @alternatives.count]
    end

    def ab_test? alt
      self.ab_test == alt
    end
  end

  module ExperimentMethods
    attr_reader :experiments

    def add_experiment(exp)
      @experiments ||= {}
      raise "Experiment already defined!" if @experiments[exp.slug]
      @experiments[exp.slug] = exp
    end

    # For tracking metrics in an experiment, use:
    # Modesty.track! :metric/:experiment/:alternative
    def new_experiment(slug, &block)
      exp = Experiment.new(slug)
      yield Experiment::Builder.new(exp) if block
      exp.alternatives.each do |a|
        exp.metrics.each do |m|
          Modesty.new_metric(m.slug/exp.slug/a, m)
        end
      end
      add_experiment(exp)
      exp
    end

    # Usage:
    # >> ab_test :experiment/:alternative do
    # >>   #something
    # >> end
    def ab_test(sym, &blk)
      exp, alt = sym.to_s.split(/\//).map { |s| s.to_sym }
      exp = Modesty.experiments[exp]
      yield if exp.ab_test? alt
    end
  end

  class << self
    include ExperimentMethods
  end
end
