module Modesty
  class Experiment
    def group(id=Modesty.identity)
      return :control unless id
      self.alternatives[
        "#{@slug}#{id}".hash % self.alternatives.count
      ]
    end

    # usage: `e.group?(:experiment)`
    def group?(alt)
      self.group == alt
    end
  end
end
