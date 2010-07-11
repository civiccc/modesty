class MockRedis
  LIB_DIR = File.dirname(__FILE__)
end

$:.unshift MockRedis::LIB_DIR
require 'mock_redis/misc.rb'
require 'mock_redis/string.rb'
require 'mock_redis/set.rb'
require 'mock_redis/hash.rb'
$:.shift
