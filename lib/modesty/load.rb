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

    def load_options(quiet = false)
      options = begin
        YAML.load(File.read(self.config_path))
      rescue Errno::ENOENT
        puts "No Modesty config file found" unless quiet
        {}
      end
      options[self.environment] || options['default'] || options
    end

    def load_paths(options)
      if options['paths']
        options['paths'].each do |data, path|
          Modesty.send("#{data}_dir=", File.join(Modesty.root, path))
        end
      end
    end

    def load_config!
      options = load_options
      load_paths(options)

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

    def _load_with_redis(redis)
      options = load_options(true)
      load_paths(options)
      self.set_store(:redis, :redis => redis)
    end

    def load!
      load_config!
      load_all_metrics!
      load_all_experiments!
    end

    def load_with_redis!(redis)
      _load_with_redis(redis)
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
