Modesty.root = Rails.root
Rails.configuration.after_initialize do
  Modesty.load!
end
