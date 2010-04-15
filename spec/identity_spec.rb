require 'modesty'

describe Modesty, "Working with identities" do
  before :each do
    @id = rand 10**10
  end

  it "can make an identity" do
    Modesty.identify! @id
    Modesty.identity.should == @id
  end

  it "can identify as nil" do
    Modesty.identify! nil
    Modesty.identity.should be_nil
  end

  after :all do
    Modesty.instance_variable_set("@identity", nil)
  end
end

describe Modesty, "contextual identity" do
  before :all do
    Modesty.experiments.clear
    Modesty.metrics.clear
    Modesty.data.flushdb
  end

  it "can make an experiment with contextual identities for its metrics" do
    Modesty.new_metric :donation_amount
    Modesty.new_metric :donation
    Modesty.new_metric :creation

    Modesty.new_experiment :creation_page do |e|
      e.metric :creation
      e.metric :donation, :by => :creator
      e.metric :donation_amount, :by => :creator
    end
  end

  it "leaves the other metrics alone" do
    e = Modesty.experiments[:creation_page]
    e.chooses :experiment, :for => 700
    Modesty.identify! 700
    e.group.should == :experiment

    Modesty.track! :creation
    m = Modesty.metrics[:creation/:creation_page/:experiment]
    m.distribution.should == {1 => 1}
  end

  it "expects a passed-in identity for the specified metrics" do
    lambda do
      Modesty.track! :donation
    end.should raise_error(Modesty::IdentityError)
  end

  it "aggregates counts by the contextual identity's experiment group" do
    e = Modesty.experiments[:creation_page]
    e.chooses :control, :for => 600
    Modesty.identify! 600
    lambda do
      #user 600 donated 10 bucks to user 700's birthday wish!
      Modesty.track! :donation_amount, 10, :creator => 700
    end.should_not raise_error
    group_exp = Modesty.metrics[:donation_amount/:creation_page/:experiment]
    group_exp.distribution.should == {10 => 1}
    group_ctrl = Modesty.metrics[:donation_amount/:creation_page/:control]
    group_ctrl.distribution.should == {}

    e.chooses :experiment, :for => 500
    #user 500 donated 2000 to 600's wish
    Modesty.identify! 500
    Modesty.track! :donation_amount, 2000, :creator => 600

    group_exp.distribution.should == {10 => 1}
    group_ctrl.distribution.should == {2000 => 1}
  end
end
