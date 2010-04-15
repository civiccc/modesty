# from assaf's Vanity; http://github.com/assaf/vanity
require 'set'

# The Redis you should never use in production.
class MockRedis
  @@hash = {}

  def hash
    @@hash
  end

  def initialize(options = {})
  end
end

$:.push(File.dirname(__FILE__))
require 'mock_redis/hash.rb'
require 'mock_redis/set.rb'
require 'mock_redis/string.rb'
require 'mock_redis/misc.rb'
$:.pop
