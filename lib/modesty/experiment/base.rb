module Modesty
  class Experiment

    def initialize(slug)
      @slug = slug
    end

    def inspect
      "#<Modesty::Experiment[ #{self.slug.inspect} ]>"
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

    def metrics(alt=nil)
      @metrics ||= []
      return @metrics unless alt
      raise Error, <<-msg.squish unless self.alternatives.include? alt
        Unrecognized alternative #{alt.inspect} for #{self.inspect}.
        Available alternatives: #{self.alternatives.inspect}
      msg

      Hash[@metrics.map do |m|
        [m.slug, m/(self.slug/alt)]
      end]
    end

  end
end
