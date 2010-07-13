require 'modesty'

describe Modesty::Metric, "Creating Metrics" do
  before :all do
    Modesty.set_store :redis, :mock => true
  end

  before :each do
    Modesty.metrics.clear
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
end

describe Modesty::Metric, "Tracking Metrics" do
  before :each do
    Modesty.set_store :redis, :mock => true
    Modesty.data.flushdb
    Modesty.metrics.clear
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

  describe "can track with custom data" do
    before :each do
      @m = Modesty.metrics[:foo/:bar]
      lambda do
        Modesty.track! :foo/:bar, :with => {:zing => 56, :user => 1}
      end.should_not raise_error
      @m.unique(:zings).should == 1
      @m.all(:zings).should include 56

      lambda do
        Modesty.track! :foo/:bar, :with => {:zing => 97, :user => 2}, :count => 4
      end.should_not raise_error
      @m.unique(:zings).should == 2
      @m.all(:zings).should include 97

      lambda do
        Modesty.track! :foo/:bar, 7, :with => {:zing => 97}
      end.should_not raise_error
    end

    it "and count unique" do
      @m.unique(:zings).should == 2
      @m.unique(:zings, :all).should == 2
    end

    it "and bucket by dates" do
      @m.unique(:zings, Date.parse('1/1/2002')).should == 0
    end

    it "and count all" do
      @m.all(:zings).count.should == 2
    end


    it "and keep an aggregate by users" do
      @m.aggregate.should == {1 => 1, 2 => 4}
    end

    it "and keep a distribution by users" do
      @m.distribution.should == {1 => 1, 4 => 1}
      @m.distribution(:all).should == {1 => 1, 4 => 1}
    end

    it "and keep an aggregate by custom data" do
      @m.aggregate_by(:zings).should == {56 => 1, 97 => 11}
    end

    it "and keep a distribution by custom data" do
      @m.distribution_by(:zings).should == {1 => 1, 11 => 1}
    end

  end
end
