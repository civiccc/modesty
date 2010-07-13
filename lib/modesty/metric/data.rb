module Modesty
  class Metric

    def data
      @data ||= (Modesty.data.class)::MetricData.new(self)
    end

    def parse_date(date)
      if date.is_a? Symbol
        return date if date == :all
        Date.send(date)
      elsif date.nil?
        Date.today
      else
        date.to_date
      end
    end

    def parse_date_or_range(start=nil,fin=nil)
      if fin
        parse_date(start)..parse_date(fin)
      elsif start.is_a?(Range)
        parse_date(start.first)..parse_date(start.last)
      else
        parse_date(start)
      end
    end


    def count(*dates)
      date_or_range = parse_date_or_range(*dates)

      case date_or_range
      when Range
        if self.data.respond_to? :count_by_range
          self.data.count_range(date_or_range)
        else
          date_or_range.map do |date|
            self.data.count(date)
          end
        end
      when Date, :all
        self.data.count(date_or_range)
      end
    end

    # for grep:
    # def all
    # def unique
    # def distribution_by
    # def aggregate_by
    [
      :all,
      :unique,
      :distribution_by,
      :aggregate_by
    ].each do |data_type|
      by_range = :"#{data_type}_range"
      define_method(data_type) do |sym, *dates|
        sym = sym.to_s.singularize.to_sym
        date_or_range = (dates.empty?) ? :all : parse_date_or_range(*dates)
        if date_or_range.is_a? Range
          if self.data.respond_to?(by_range)
            return self.data.send(by_range, sym, date_or_range)
          else
            return date_or_range.map do |date|
              self.data.send(data_type, sym, date)
            end
          end
        elsif date_or_range.is_a?(Date) || date_or_range == :all
          return self.data.send(data_type, sym, date_or_range)
        end
      end
    end

    # def distribution
    # def aggregate
    # helpers to use the default context if it's an experiment-generated metric
    # otherwise default to users
    %w(
      distribution
      aggregate
    ).each do |data_type|
      define_method data_type do |*dates|
        context = if @experiment
          @experiment.identity_for(self.parent)
        else
          :user
        end
        send("#{data_type}_by", context, *dates)
      end
    end

    def track!(count=1, options={})
      if count.is_a? Hash
        options = count
        count = options[:count] || 1
      end

      with = options[:with] || {}

      with[:user] ||= Modesty.identity if Modesty.identity
      self.experiments.each do |exp|
        # only track the for the experiment group if
        # the user has previously hit the experiment
        identity_slug = exp.identity_for(self)
        identity = if identity_slug
          i = with[identity_slug]
          raise IdentityError, """
            #{exp.inspect} requires #{self.inspect} to be tracked
            with #{identity_slug.to_s.singularize.to_sym.inspect}.

            It was tracked :with => #{with.inspect}
          """.squish unless i
          i
        else
          Modesty.identity
        end
        if identity
          alt = exp.data.get_cached_alternative(identity)
          if alt
            (self/(exp.slug/alt)).data.track!(count, with)
          end
        end
      end

      self.data.track!(count, with)
      @parent.track!(count, :with => with) if @parent
    end
  end
end
