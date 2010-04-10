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
        metrics = args.map do |s|
          Modesty.metrics[s] || raise(Modesty::NoMetricError, "Undefined metric '#{s}'")
        end
        @exp.instance_variable_set("@metrics", metrics)
      end
    end

    def initialize(slug)
      @slug = slug
    end

    class << self
      attr_writer :dir
      def dir
        @dir ||= File.join(Modesty.root, 'experiments')
      end

      def load_all!
        Dir.glob(
          File.join(self.dir, '*.rb')
        ).each { |f| load f }
      end
    end

    ATTRIBUTES = [
      :description,
      :alternatives,
    ]

    attr_reader *ATTRIBUTES 
    attr_reader :slug
    attr_reader :metrics

    def data
      @data ||= (Modesty.data.class)::ExperimentData.new(self)
    end

    def chooses(alt)
      self.data.register! alt
    end

    def register!
      self.data.register!
    end

    def users(alt=nil)
      self.data.users(alt)
    end

    def num_users(alt=nil)
      self.data.num_users(alt)
    rescue NoMethodError
      self.users(alt).count
    end

    def ab_test
      raise Modesty::IdentityError, "Try calling Modesty.identify! first." unless Modesty.identity
      self.data.get_cached_alternative || self.generate_alternative
    end

    def generate_alternative
      self.data.register! @alternatives[ 
        "#{@slug}#{Modesty.identity}".hash % @alternatives.count
      ]
    end

    def ab_test?(alt)
      self.ab_test == alt
    end
  end

  module ExperimentMethods
    attr_accessor :experiments

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

    def get_experiment(sym)
      exp = Modesty.experiments[sym]
      exp.register!
      exp
    end

    # Usage:
    # >> Modesty.ab_test :experiment/:alternative do
    # >>   #something
    # >> end
    # Or:
    # >> ab_test :experiment
    # => :current_alternative
    def ab_test(sym)
      if sym.to_s['/']
        exp, alt = sym.to_s.split(/\//).map { |s| s.to_sym }
        exp = self.get_experiment(exp)
        yield if block_given? && exp.ab_test?(alt)
      else
        exp = self.get_experiment(sym)
        exp.ab_test
      end
    end

    # Usage:
    # if Modesty.ab_test? :experiment/:alternative
    #   #something
    # else
    #   #something else
    # end
    def ab_test?(sym)
      exp, alt = sym.to_s.split(/\//).map { |s| s.to_sym }
      exp = self.get_experiment(exp)
      exp.ab_test? sym
    end
  end

  class << self
    include ExperimentMethods
  end
end
