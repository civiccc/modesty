require 'modesty'

describe "loading metrics" do
  before :all do
    Modesty.root = File.join(
      Modesty::TEST,
      'myapp'
    )

    Modesty.metrics = {}
  end

  it "can load metrics" do
    lambda do
      Modesty.load_all_metrics!
    end.should_not raise_error
  end

  it "actually loads the metrics" do
    [
      :baked_goods,
      :baked_goods/:cookies,
      :baked_goods/:brownies,
      :baked_goods/:cake,
      :baked_goods/:cake/:chocolate,
      :baked_goods/:cake/:ice_cream,
    ].each do |m|
      Modesty.metrics.should include m
    end
  end

  after :all do
    Modesty.root = nil
    Modesty.metrics = {}
  end
end

describe "Loading experiments" do
  before :all do
    Modesty.load_all_metrics!
    Modesty.experiments = {}
  end

  it "can load experiments" do
    lambda do
      Modesty.load_all_experiments!
    end.should_not raise_error
  end

  it "actually loads experiments" do
    Modesty.experiments.should include :cookbook
  end

  after :all do
    Modesty.metrics = {}
    Modesty.experiments = {}
  end
end
