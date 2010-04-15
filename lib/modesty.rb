require 'yaml'
require 'rubygems'
require 'active_support'


module Modesty
  LIB = File.dirname(__FILE__)
  VENDOR = File.expand_path(File.join(LIB, '..', 'vendor'))
end

$:.unshift Modesty::LIB
require 'modesty/core_ext.rb'
require 'modesty/api.rb'
require 'modesty/datastore.rb'
require 'modesty/identity.rb'
require 'modesty/metric.rb'
require 'modesty/experiment.rb'
require 'modesty/load.rb'
$:.shift

if defined? Rails
  require 'modesty/frameworks/rails'
end
