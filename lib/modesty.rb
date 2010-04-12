require 'yaml'

$:.unshift File.dirname(__FILE__)

module Modesty
  ROOT = File.dirname(__FILE__)
  class << self
    attr_writer :root
    def root
      @root ||= File.join(
        File.dirname(__FILE__),
        '..'
      )
      #TODO: is there a better default?
    end

    attr_writer :config_path
    def config_path
      @config_path ||= File.join(
        Modesty.root,
        'config/modesty.yml'
      )
    end


    def load_config!
      options = begin
        YAML.load(File.read(self.config_path))
      rescue Errno::ENOENT 
        {}
      end

      if options['datastore'] && options['datastore']['type']
        type = options['datastore']['type']
        options['datastore'].delete 'type'
        data_options = Hash[
          options['datastore'].map { |k,v| [k.to_sym, v] }
        ]
        self.set_store(type, data_options)
      else
        self.set_store('mock')
      end
    end

    def load!
      load_config!
      Metric.load_all!
      Experiment.load_all!
    end
  end
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
require 'modesty/experiment/stat'

if defined? Rails
  require 'modesty/frameworks/rails'
end
