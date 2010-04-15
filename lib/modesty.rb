require 'yaml'
require 'rubygems'
require 'active_support'

$:.unshift File.dirname(__FILE__)

module Modesty
  ROOT = File.dirname(__FILE__)
end

$: << File.join(
  File.dirname(__FILE__),
  '../vendor/redis-rb/lib'
)

require 'modesty/core_ext'
require 'modesty/datastore'
require 'modesty/identity'
require 'modesty/metric'
require 'modesty/experiment'
require 'modesty/load'

if defined? Rails
  require 'modesty/frameworks/rails'
end
