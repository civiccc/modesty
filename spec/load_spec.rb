require 'modesty'

describe "the config file" do
  before :all do
    Modesty.root = File.join(
      Modesty::TEST,
      'myapp',
      'modesty'
    )
    Modesty.environment = 'test'
    Modesty.load_config!
  end

  it "can set the metrics directory" do
    Modesty.metrics_dir.should ==
      File.expand_path(
        File.join(
          File.dirname(__FILE__),
          "../test/myapp/modesty/metrics"
        )
      )
  end

  after :all do
    Modesty.root = nil
  end
end

describe "loading metrics" do
  before :all do
    Modesty.root = File.join(
      Modesty::TEST,
      'myapp'
    )

    Modesty.environment = 'test'
    Modesty.metrics.clear
  end

  it "can load metrics" do
    lambda do
      Modesty.load_all_metrics!
    end.should_not raise_error
  end

  it "doesn't try to load directories" do
    lambda do
      Modesty.load_all_metrics!
    end.should_not raise_error(Errno::EISDIR)
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
  end
end

describe "Loading experiments" do
  before :all do
    Modesty.environment = 'test'
    Modesty.metrics.clear
    Modesty.experiments.clear
    Modesty.load_all_metrics!
  end

  it "can load experiments" do
    lambda do
      Modesty.load_all_experiments!
    end.should_not raise_error
  end

  it "actually loads experiments" do
    Modesty.experiments.should include :cookbook
  end
end
