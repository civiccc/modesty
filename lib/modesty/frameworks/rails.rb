if Rails.version.match('^3')
  module Modesty
    class Railtie < Rails::Railtie
      initializer "modesty.initialize" do |app|
        Modesty.root = File.join(Rails.root, 'modesty')
        Modesty.config_path = File.join(Rails.root, 'config', 'modesty.yml')
        Modesty.environment = Rails.env
      end

      config.after_initialize do
        begin
          Modesty.load_with_redis!(config.redis)
        rescue NoMethodError
          Modesty.load!
        end
      end

    end
  end
else
  Modesty.root = File.join(Rails.root, 'modesty')
  Modesty.config_path = File.join(Rails.root, 'config', 'modesty.yml')
  Modesty.environment = Rails.env
  Rails.configuration.after_initialize do
    Modesty.load!
  end
end
