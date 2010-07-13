module Modesty
  class Experiment
    def data
      @data ||= (Modesty.data.class)::ExperimentData.new(self)
    end

    def chooses(alt, options={})
      raise Experiment::Error, <<-msg.squish unless self.alternatives.include? alt
        Unknown alternative #{alt.inspect}
      msg

      id = options.include?(:for) ? options[:for] : Modesty.identity

      raise IdentityError, <<-msg.squish unless id
        Experiment#chooses doesn't work for guests.
        Either identify globally or pass in :for => id
      msg

      self.data.register!(alt, id)
    end

    def group(id=Modesty.identity)
      return :control unless id
      fetch_or_generate_group(id)
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
    def fetch_or_generate_group(id=Modesty.identity)
      alt = begin
        fetch_group(id)
      rescue Datastore::ConnectionError
        nil
      end || generate_group(id)
    end

    # generates an alternative and stores it in redis
    def generate_group(identity)
      alternative = self.alternatives[
        "#{@slug}#{identity}".hash % self.alternatives.count
      ]
      self.chooses(alternative, :for => identity)
    rescue Datastore::ConnectionError
    ensure
      return alternative
    end

  end
end
