Modesty.root = File.join(Rails.root, 'modesty')
Rails.configuration.after_initialize do
  Modesty.load!
end
