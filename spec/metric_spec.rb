require 'modesty'

describe Modesty::Metric, "Creating Metrics" do
  before :each do
    Modesty.metrics = {}
  end

  it "can create a metric without a block" do
    m = Modesty.new_metric(:foo)
    m.slug.should == :foo
    Modesty.metrics[:foo].should == m
  end

  it "can create a metric with a block" do
    m = Modesty.new_metric :foo do |m|
      m.description "Foo"
    end 
    m.slug.should == :foo
    m.description.should == "Foo"
    Modesty.metrics[:foo].should == m
  end

  it "can create submetrics" do
    Modesty.new_metric :foo do |foo|
      foo.description "Foo"

      foo.submetric :bar do |bar|
        bar.description "Bar"

        bar.submetric :baz do |baz|
          baz.description "Baz"
        end
      end
    end

    Modesty.metrics.should include :foo
    Modesty.metrics.should include :foo/:bar
    Modesty.metrics.should include :foo/:bar/:baz

    Modesty.metrics[:foo].parent.should == nil
    Modesty.metrics[:foo/:bar].parent.should_not == nil
    Modesty.metrics[:foo/:bar].parent.slug.should == :foo
    Modesty.metrics[:foo/:bar/:baz].parent.should_not == nil
    Modesty.metrics[:foo/:bar/:baz].parent.slug.should == :foo/:bar
  end

  after :all do
    Modesty.metrics = {}
  end
end

describe Modesty::Metric, "Tracking Metrics" do
  before :each do
    Modesty.redis.flushdb
  end

  before :all do
    Modesty.metrics = {}
    Modesty.new_metric :foo do |foo|
      foo.description "Foo"

      foo.submetric :bar do |bar|
        bar.description "Bar"

        bar.submetric :baz do |baz|
          baz.description "Baz"
        end
      end
    end
  end

  it "can track a metric" do
    (1..100).each do |i|
      lambda { Modesty.track! :foo }.should_not raise_error
      Modesty.metrics[:foo].total.to_i.should == i
    end
  end

  it "can track a metric with a count" do
    (1..100).each do |i|
      lambda { Modesty.track! :foo, 3 }.should_not raise_error
      Modesty.metrics[:foo].total.to_i.should == i*3
    end
  end

  it "can track one submetric" do
    (1..100).each do |i|
      lambda { Modesty.track! :foo/:bar }.should_not raise_error
      Modesty.metrics[:foo].total.to_i.should == i
      Modesty.metrics[:foo/:bar].total.to_i.should == i
      Modesty.metrics[:foo/:bar/:baz].total.to_i.should == 0
    end
  end

  it "can track more than one submetric" do
    (1..100).each do |i|
      lambda { Modesty.track! :foo/:bar/:baz }.should_not raise_error
      Modesty.metrics[:foo].total.to_i.should == i
      Modesty.metrics[:foo/:bar].total.to_i.should == i
      Modesty.metrics[:foo/:bar/:baz].total.to_i.should == i
    end
  end

  it "raises Modesty::NoMetricError if it can't find your metric" do
    lambda { Modesty.track! :oh_noes }.should raise_error Modesty::NoMetricError
  end
end
