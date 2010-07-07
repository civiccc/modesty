module Modesty
  class Experiment
    def data
      @data ||= (Modesty.data.class)::ExperimentData.new(self)
    end

    def chooses(alt, options={})
      id = options.include?(:for) ? options[:for] : Modesty.identity

      @group[id] = alt
      self.data.register!(alt, options[:for])
      self.data.register!(alt, Modesty.identity)
    end

    def group(id=Modesty.identity)
      return :control unless id
      @group ||= {}
      @group[id] ||= set_group(id)
    end

    # usage: `e.group?(:experiment)`
    def group?(alt)
      self.group == alt
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

  private
    # used to fetch the cached alternative from redis
    def fetch_group(identity)
      self.data.get_cached_alternative(identity)
    end

    # this is the method with the fallbacks - fetch it from redis or create it.
    def group_for(id)
      self.fetch_group(Modesty.identity) || self.generate_alternative(Modesty.identity)
    rescue Datastore::ConnectionError
      self.generate_alternative(Modesty.identity)
    end

    # generates an alternative and stores it in redis
    def generate_alternative(identity)
      alternative = self.alternatives[
        "#{@slug}#{identity}".hash % self.alternatives.count
      ]
      self.chooses(alternative)
    ensure
      return alternative
    end

  end
end
