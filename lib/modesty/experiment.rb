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
    end

    def initialize(slug)
      @slug = slug
    end

    ATTRIBUTES = [
      :description,
      :alternatives,
      :metrics,
    ]
    attr_reader *ATTRIBUTES 
    attr_reader :slug
  end

  module ExperimentMethods
    def add_experiment(exp)
      @experiments ||= {}
      raise "Experiment already defined!" if @experiments[exp.slug]
      @experiments[exp.slug] = exp
    end

    def new_experiment(slug, &block)
      exp = Experiment.new(slug)
      yield Experiment::Builder.new(exp) if block
      exp.alternatives.each do |a|
        exp.metrics.each do |m|
          Modesty.new_metric(m.slug/a.slug, m)
        end
      end
      add_experiment(exp)
      exp
    end
  end

  class << self
    include ExperimentMethods
  end
end
