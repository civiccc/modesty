module Modesty
  module LoadMethods
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
        '../config/modesty.yml'
      )
    end

    attr_accessor :environment

    def load_config!
      options = begin
        YAML.load(File.read(self.config_path))
      rescue Errno::ENOENT
        puts "No Modesty config file found"
        {}
      end

      options = options[self.environment] || options['default'] || options

      if options['paths']
        options['paths'].each do |data, path|
          Modesty.send("#{data}_dir=", File.join(Modesty.root, path))
        end
      end

      if options['datastore'] && options['datastore']['type']
        type = options['datastore'].delete('type')
        data_options = Hash[
          options['datastore'].map { |k,v| [k.to_sym, v] }
        ]
        self.set_store(type, data_options)
      else
        self.set_store :redis, :mock => true
      end
    end

    def load!
      load_config!
      load_all_metrics!
      load_all_experiments!
    end
  end

  class API
    include LoadMethods
  end
end

require 'modesty/load/load_experiments.rb'
require 'modesty/load/load_metrics.rb'
