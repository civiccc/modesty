module Modesty
  class Experiment
    # the thing yielded when you say `Modesty.experiment :foo do |e| ...`
    class Interface
      def initialize(exp, identity)
        @exp = exp
        @alt = exp.group(identity)
      end

      attr_reader :last_value

      def group(gr=nil)
        if block_given?
          if gr && @exp.group == gr
            @last_value = yield
          else
            @last_value
          end
        else
          @exp.group
        end
      end

      def group?(alt)
        alt == @alt
      end
    end
  end
end
