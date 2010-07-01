module Modesty
  class Experiment
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

    def fetch_group
      self.data.get_cached_alternative
    end

    def choose_group
      return :control unless Modesty.identity #guests get the control group.
      self.fetch_group(Modesty.identity) || self.generate_alternative(Modesty.identity)
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
end
