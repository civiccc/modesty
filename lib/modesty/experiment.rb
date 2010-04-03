module Modesty
  class Experiment
    class Builder
      def method_missing(name, *args)
        if Experiment::ATTRIBUTES.include? name
          @exp.instance_variable_set("@#{name}", args[0])
        else
          super
        end
      end

      def initialize(exp)
        @exp = exp
      end
    end

    ATTRIBUTES = [
      :description,
      :alternatives,
      :metrics,
    ]
    attr_reader *ATTRIBUTES 
    attr_reader :slug
  end

  class << self

  end
end
