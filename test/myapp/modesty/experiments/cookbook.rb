Modesty.new_experiment :cookbook do |e|
  e.alternatives :big, :medium, :small
  e.metrics :baked_goods/:cookies, :baked_goods/:brownies, :baked_goods/:cake
end
