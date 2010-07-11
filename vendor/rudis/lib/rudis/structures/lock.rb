class Rudis
  class Lock < Structure
    class LockFailed < Exception; end

    def acquire(options={})
      options.rmerge!(
        :tries => 1,
        :sleep => 1
      )

      return set(options) unless block_given?

      1.upto options[:tries] do
        if set(options)
          return begin
            yield
          ensure
            clear
          end
        end
        sleep options[:sleep]
      end

      # oops, we couldn't get the lock
      raise LockFailed, <<-msg.squish
        Unable to acquire lock after #{options[:tries]} time(s)
      msg
      return false
    end

    # implements the SETNX locking algorithm from
    # http://code.google.com/p/redis/wiki/SetnxCommand
    def set(options={})
      options.rmerge!(
        :timeout => 30
      )
      if redis.setnx(key, timestamp(options[:timeout]))
        return true
      else
        # check the timestamp
        old = redis.getset(key, timestamp(options[:timeout]))
        if old < timestamp
          # expired lock, we're good
          return true
        else
          # lock is not expired, put it back
          redis.set(key, old)
          return false
        end
      end
    end

    alias clear del

  private
    def timestamp(timeout=0)
      Time.now.to_i + timeout
    end

  end
end
