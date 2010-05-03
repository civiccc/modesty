require 'yaml'
require 'rubygems'
require 'active_support'


module Modesty
  LIB = File.dirname(__FILE__)
  ROOT = File.expand_path(File.join(LIB, '..'))
  VENDOR = File.expand_path(File.join(ROOT, 'vendor'))
  TEST = File.expand_path(File.join(ROOT, 'test'))
end

$:.unshift Modesty::LIB
require 'modesty/core_ext.rb'
require 'modesty/api.rb'
require 'modesty/datastore.rb'
require 'modesty/identity.rb'
require 'modesty/metric.rb'
require 'modesty/experiment.rb'
require 'modesty/load.rb'

if defined? Rails
  require 'modesty/frameworks/rails'
end

$:.shift
