Modesty.root = Rails.root
Rails.after_initialize do
  Modesty.load!
end
