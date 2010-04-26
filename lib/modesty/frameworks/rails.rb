Modesty.root = File.join(Rails.root, 'modesty')
Modesty.config_path = File.join(Rails.root, 'config/modesty.yml')
Rails.configuration.after_initialize do
  Modesty.load!
end
