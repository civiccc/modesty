require 'modesty'

describe "Significance" do
  before :each do
    Modesty.data.flushdb
    Modesty.experiments.clear
    Modesty.metrics.clear

    @foo = Modesty.new_metric :foo
    @bar = Modesty.new_metric :bar

    @e = Modesty.new_experiment :baz do |e|
      e.metrics :foo, :bar

      e.conversion :foo_conv, :on => [:foo, :bar]
      e.distribution :foo_dist, :on => :foo
    end

    @foo_dist = @e.stats[:foo_dist]
    @foo_conv = @e.stats[:foo_conv]

    Modesty.identify! 1
  end

  it "handles significant distribution data" do
    250.times do |uid|
      @e.chooses :experiment, :for => uid
      Modesty.track! :foo, rand(200), :with => {:user => uid}
    end

    250.times do |uid|
      uid = 251 + uid
      @e.chooses :control, :for => uid
      Modesty.track! :foo, rand(100), :with => {:user => uid}
    end

    @foo_dist.should be_a Modesty::Experiment::DistributionStat
    an = @foo_dist.analysis
    an.should be_a Hash
    an[:control][:mean].should be_close(50, 10)
    an[:experiment][:mean].should be_close(100, 20)
    an[:control][:size].should == 250
    an[:experiment][:size].should == 250

    sig = @foo_dist.significance
    sig.should be_a Float
    sig.should be < 0.01
    @foo_dist.should be_significant
  end

  it "handles insignificant distribution data" do
    @e.chooses :experiment
    250.times do
      Modesty.track! :foo, 1+rand(10)
    end
    @e.chooses :control
    250.times do
      Modesty.track! :foo, 1+rand(10)
    end

    sig = @foo_dist.significance
    sig.should be_nil
    @foo_dist.should_not be_significant
  end

  it "handles significant conversion data" do
    @e.chooses :experiment
    500.times do
      Modesty.track! :foo, 1+rand(5)
      Modesty.track! :bar, 100
    end

    @e.chooses :control
    500.times do
      Modesty.track! :foo, 1+rand(100)
      Modesty.track! :bar, 100
    end

    @foo_conv.should be_a Modesty::Experiment::ConversionStat
    sig = @foo_conv.significance
    sig.should_not be_nil
  end
end

describe "Statistics with blocks" do
  before :each do
    Modesty.data.flushdb
    Modesty.metrics.clear
    Modesty.experiments.clear

    Modesty.new_metric :foo
    Modesty.new_metric :bar

    @e = Modesty.new_experiment :baz do |e|
      e.metrics :foo, :bar

      e.distribution :special_dist do |metrics|
        metrics[:foo].distribution + metrics[:bar].distribution
      end

      e.conversion :special_conv do |metrics|
        [
          metrics[:foo].unique(:users),
          metrics[:foo].count
        ]
      end
    end

    (1..500).each do |i| 
      Modesty.identify!(i)
      Modesty.group :baz
      Modesty.track! :foo, 1+rand(i)
      Modesty.track! :bar, 1+rand(501-i)
    end

  end

  it "uses the blocks for distribution" do
    three_days = @e.stats[:special_dist].data(3.days.ago..Date.today)
    three_days.should == {
      :control => (
        @e.metrics(:control)[:foo].distribution(3.days.ago..Date.today).sum +
        @e.metrics(:control)[:bar].distribution(3.days.ago, Date.today).sum
      ),
      :experiment => (
        @e.metrics(:experiment)[:foo].distribution(3.days.ago, :today).sum +
        @e.metrics(:experiment)[:bar].distribution(3.days.ago..Date.today).sum
      )
    }

    three_days.should == @e.stats[:special_dist].data(3.days.ago, :today)
  end

  it "uses the blocks for conversion" do
    three_days = @e.stats[:special_conv].data(3.days.ago..Date.today)
    three_days.should == [
      [
        @e.metrics(:control)[:foo].unique(:users, 3.days.ago..Date.today).sum,
        @e.metrics(:control)[:foo].count(3.days.ago, :today).sum
      ],
      [
        @e.metrics(:experiment)[:foo].unique(:users, 3.days.ago, :today).sum,
        @e.metrics(:experiment)[:foo].count(3.days.ago, Date.today).sum
      ],
    ]
  end
end
