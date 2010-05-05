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
      e.conversion :foo, :bar
      e.distribution :foo
    end

    Modesty.identify! 1
  end

  it "handles significant distribution data" do
    @e.chooses :experiment
    250.times do
      Modesty.track! :foo, rand(200)
    end

    @e.chooses :control
    250.times do
      Modesty.track! :foo, rand(100)
    end

    @e.stats[1].should be_a Modesty::Experiment::DistributionStat
    an = @e.stats[1].analysis
    an.should be_a Hash
    an[:control][:mean].should be_close(50, 10)
    an[:experiment][:mean].should be_close(100, 20)
    an[:control][:size].should == 250
    an[:experiment][:size].should == 250

    sig = @e.stats[1].significance
    sig.should be_a Float
    sig.should be < 0.01
    @e.stats[1].should be_significant
  end

  it "handles insignificant distribution data" do
    @e.chooses :experiment
    250.times do
      Modesty.track! :foo, rand(10)
    end
    @e.chooses :control
    250.times do
      Modesty.track! :foo, rand(10)
    end

    sig = @e.stats[1].significance
    sig.should be_nil
    @e.stats[1].should_not be_significant
  end

  it "handles significant conversion data" do
    @e.chooses :experiment
    500.times do
      Modesty.track! :foo, rand(5)
      Modesty.track! :bar, 100
    end

    @e.chooses :control
    500.times do
      Modesty.track! :foo, rand(100)
      Modesty.track! :bar, 100
    end

    @e.stats[0].should be_a Modesty::Experiment::ConversionStat
    sig = @e.stats[0].significance
    sig.should_not be_nil
  end
end
