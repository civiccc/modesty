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
          "Undefined metric #{s.inspect} in experiment #{@exp}"
        ))
        if options[:by]
          @exp.metric_contexts.merge!({sym => options[:by].to_s.pluralize.to_sym})
        end
      end
    end

    def initialize(slug)
      @slug = slug
    end

    ATTRIBUTES = [
      :description,
    ]

    def identity_for(sym)
      sym = sym.slug if sym.is_a? Metric
      self.metric_contexts[sym]
    end

    attr_reader *ATTRIBUTES 
    attr_reader :slug
    attr_reader :metrics

    def metric_contexts
      @metric_contexts ||= {}
    end

    def alternatives
      @alternatives ||= [:control, :experiment]
    end

    def metrics
      @metrics ||= []
    end

    def data
      @data ||= (Modesty.data.class)::ExperimentData.new(self)
    end

    def chooses(alt, options={})
      if options.include? :for
        self.data.register!(alt, options[:for])
      else
        self.data.register!(alt, Modesty.identity)
      end
    end

    attr_reader :last_value
    def group(group=nil)
      if block_given?
        if group && self.choose_group == group
          @last_value = yield
        else
          @last_value
        end
      else
        self.choose_group
      end
    end

    def group?(alt)
      self.choose_group == alt
    end

    def choose_group
      return :control unless Modesty.identity #guests get the control group.
      self.data.get_cached_alternative(Modesty.identity) || self.generate_alternative(Modesty.identity)
    rescue Datastore::ConnectionError
      self.generate_alternative(Modesty.identity)
    end

    def generate_alternative(identity)
      alternative = self.alternatives[ 
        "#{@slug}#{identity}".hash % self.alternatives.count
      ]
      self.chooses(alternative)
    ensure
      return alternative
    end

    def num_users(alt=nil)
      if self.data.respond_to? :num_users
        self.data.num_users(alt)
      else
        self.users(alt).count
      end
    end

    def users(alt=nil)
      self.data.users(alt)
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

    def experiment(exp, options={}, &blk)
      exp = self.experiments[exp]

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
