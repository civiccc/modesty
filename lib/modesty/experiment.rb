module Modesty
  class Experiment
    class Error < StandardError; end
  end

  module ExperimentMethods
    def experiments
      @experiments ||= Hash.new do |h, k|
        raise Experiment::Error, <<-msg.squish
          Unrecognized experiment #{k.inspect}.
        msg
      end
    end

    def add_experiment(exp)
        raise Experiment::Error, <<-msg if self.experiments.include? exp.slug
          Experiment #{exp.slug.inspect} already defined!
        msg
      self.experiments[exp.slug] = exp
    end

    def new_experiment(slug, &block)
      exp = Experiment.new(slug)
      yield Experiment::Builder.new(exp) if block
      exp.metrics.each do |m|
        m.experiments << exp
        exp.alternatives.each do |a|
          Modesty.new_metric(m.slug/exp.slug/a, m)
        end
      end
      add_experiment(exp)
      exp
    end

    def decide_identity(options)
      if options.include? :identity
        options[:identity]
      elsif options.include? :for
        options[:for]
      elsif options.include? :on
        options[:on]
      else
        Modesty.identity
      end
    end

    def experiment(sym, options={}, &blk)
      exp = self.experiments[sym]

      identity = decide_identity(options)

      self.with_identity identity do
        yield exp
      end

      exp.last_value
    end

    def group?(sym)
      exp = sym.to_s.split(/\//)
      alt = exp.pop.to_sym
      exp = exp.join('/').to_sym
      exp = self.experiments[exp]
      exp.group? alt
    end

    def group(sym)
      exp = self.experiments[sym]
      exp ? exp.group : :control
    end
  end

  class API
    include ExperimentMethods
  end
end

require 'modesty/experiment/base'
require 'modesty/experiment/builder'
require 'modesty/experiment/data'
require 'modesty/experiment/significance'
require 'modesty/experiment/stats'
