require 'modesty'

describe Modesty::Metric, "Creating Metrics" do
  before :all do
    Modesty.set_store :redis, :mock => true
  end

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
    Modesty.data.flushdb
  end

  before :all do
    Modesty.set_store :redis, :mock => true
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
    Modesty.data.flushdb
  end

  it "can track a metric" do
    (1..100).each do |i|
      lambda { Modesty.track! :foo }.should_not raise_error
      Modesty.metrics[:foo].count.to_i.should == i
    end
  end

  it "can track a metric with a count" do
    (1..100).each do |i|
      lambda { Modesty.track! :foo, 3 }.should_not raise_error
      Modesty.metrics[:foo].count.to_i.should == i*3
    end
  end

  it "can fetch a metric for a date" do
    now = Time.now
    Time.stub!(:now).and_return(now-1.day)
    25.times {|i| Modesty.track! :foo}
    Modesty.metrics[:foo].count((now-1.day).to_date).should == 25
  end

  it "can fetch a metric over a date range" do
    now = Time.now
    Time.stub!(:now).and_return(now-1.day)
    25.times {|i| Modesty.track! :foo}
    Time.stub!(:now).and_return(now)
    50.times {|i| Modesty.track! :foo}
    Modesty.metrics[:foo].count((now-1.day).to_date..(now.to_date)).should == [25, 50]
  end

  it "can fetch a metric over a date range as array" do
    now = Time.now
    Time.stub!(:now).and_return(now-1.day)
    25.times {|i| Modesty.track! :foo}
    Time.stub!(:now).and_return(now)
    50.times {|i| Modesty.track! :foo}
    Modesty.metrics[:foo].count((now-1.day).to_date, now.to_date).should == [25, 50]
  end

  it "can track one submetric" do
    (1..100).each do |i|
      lambda { Modesty.track! :foo/:bar }.should_not raise_error
      Modesty.metrics[:foo].count.to_i.should == i
      Modesty.metrics[:foo/:bar].count.to_i.should == i
      Modesty.metrics[:foo/:bar/:baz].count.to_i.should == 0
    end
  end

  it "can track more than one submetric" do
    (1..100).each do |i|
      lambda { Modesty.track! :foo/:bar/:baz }.should_not raise_error
      Modesty.metrics[:foo].count.to_i.should == i
      Modesty.metrics[:foo/:bar].count.to_i.should == i
      Modesty.metrics[:foo/:bar/:baz].count.to_i.should == i
    end
  end

  it "raises Modesty::NoMetricError if it can't find your metric" do
    lambda { Modesty.track! :oh_noes }.should raise_error Modesty::Metric::Error
  end

  it "can track with custom data" do
    m = Modesty.metrics[:foo/:bar]
    lambda do
      Modesty.track! :foo/:bar, :with => {:zing => 56}
    end.should_not raise_error
    m.unique(:zings).should == 1
    m.all(:zings).should include 56

    lambda do
      Modesty.track! :foo/:bar, :with => {:zing => 97}, :count => 4
    end.should_not raise_error
    m.unique(:zings).should == 2
    m.all(:zings).should include 97

    lambda do
      Modesty.track! :foo/:bar, 7, :with => {:zing => 97}
    end.should_not raise_error
    m.unique(:zings).should == 2
    m.all(:zings).count.should == 2

    m.unique(:zings, Date.parse('1/1/2002')).should == 0
    m.unique(:zings, :all).should == 2

    m.distribution_by(:zings).should == {56=>{1=>1}, 97=>{7=>1, 4=>1}}
    m.distribution.should == {1 => 1, 7 => 1, 4 => 1}

    m.distribution(:all).should == {1 => 1, 7 => 1, 4 => 1}
  end
end
