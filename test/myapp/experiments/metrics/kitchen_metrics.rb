Modesty.new_metric :baked_goods do |m|
  m.description "Yummy baked things"
  m.submetric :cookies
  m.submetric :brownies
  m.submetric :cake do |m|
    m.submetric :chocolate
    m.submetric :ice_cream
  end
end
