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

  it "can't identify as anything other than a Fixnum or nil." do
    lambda do
      Modesty.identify! "foo"
    end.should raise_error(Modesty::IdentityError)
  end

  after :all do
    Modesty.instance_variable_set("@identity", nil)
  end
end

describe Modesty, "contextual identity" do
  before :each do
    Modesty.experiments.clear
    Modesty.metrics.clear
    Modesty.data.flushdb

    Modesty.new_metric :donation_amount do |m|
      m.submetric :birthday_wish
    end
    Modesty.new_metric :donation
    Modesty.new_metric :creation

    Modesty.new_experiment :creation_page do |e|
      e.metric :creation
      e.metric :donation, :as => :creator
      e.metric :donation_amount, :as => :creator
    end
    @e = Modesty.experiments[:creation_page]
    Modesty.identify! nil

    @e.chooses :experiment, :for => 500
    @e.chooses :control, :for => 600
    @e.chooses :experiment, :for => 700
    @group_exp = Modesty.metrics[:donation_amount/:creation_page/:experiment]
    @group_ctrl = Modesty.metrics[:donation_amount/:creation_page/:control]
  end

  it "leaves the other metrics alone" do
    Modesty.with_identity 700 do
      @e.group.should == :experiment
      Modesty.track! :creation
    end

    m = Modesty.metrics[:creation/:creation_page/:experiment]
    m.distribution.should == {1 => 1}
  end

  it "expects a passed-in identity for the specified metrics" do
    Modesty.identify! 700
    lambda do
      Modesty.track! :donation
    end.should raise_error(Modesty::IdentityError)
  end

  it "aggregates counts by the contextual identity's experiment group" do
    Modesty.with_identity 600 do
      lambda do
        #user 600 donated 10 bucks to user 700's birthday wish!
        Modesty.track! :donation_amount, 10, :with => {:creator => 700}
      end.should_not raise_error
    end
    @group_exp.distribution.should == {10 => 1}
    @group_ctrl.distribution.should == {}

    @e.chooses :experiment, :for => 500
    #user 500 donated 2000 to 600's wish
    Modesty.with_identity 500 do
      Modesty.track! :donation_amount, 2000, :with => {:creator => 600}
    end

    @group_exp.distribution.should == {10 => 1}
    @group_ctrl.distribution.should == {2000 => 1}
  end

  describe "with some data" do
    before :each do
      Modesty.data.flushdb

      # users 500 and 700 hit the experiment
      @e.chooses :experiment, :for => 700
      @e.chooses :control, :for => 500

      # user 600, who is in the control group, donates $45 to user 700's wish
      Modesty.with_identity 600 do
        Modesty.track! :donation_amount, 45, :with => {:creator => 700}
      end

      # user 500, who is in the experiment group, donates $30 to user 700's wish
      Modesty.with_identity 500 do
        Modesty.track! :donation_amount/:birthday_wish, 30, :with => {:creator => 700}
      end

      # a guest donates $15 to user 700's wish
      Modesty.with_identity nil do
        Modesty.track! :donation_amount, 15, :with => {:creator => 700}
      end
    end

    it "knows its experiment" do
      @group_exp.experiment.should == @e
    end

    it "aggregates work" do
      @group_exp.aggregate_by(:creators).should == {700 => 90}
      @group_ctrl.aggregate_by(:creators).should == {}
    end

    it "distributions work" do
      @group_exp.distribution_by(:creator).should == {90 => 1}
      @group_ctrl.distribution_by(:creator).should == {}
    end

    it "defaults to the given param as identity" do
      @group_exp.aggregate.should == @group_exp.aggregate_by(:creator)
      @group_exp.distribution.should == @group_exp.distribution_by(:creator)
    end

    it "all, unique, and unidentified_users work" do
      @group_exp.all(:creators).should == [700]
      @group_exp.all(:users).sort.should == [500, 600]
      @group_exp.data.unidentified_users.should == 1
    end

    it "aggregates and distributes on the experiment" do
      @e.aggregates(:donation_amount).should == {
        :experiment => {
          700 => 90
        },
        :control => {
          500 => 0,
        }
      }
      @e.distributions(:donation_amount).should == {
        :experiment => {
          90 => 1,
        },
        :control => {
          0 => 1
        }
      }
    end
  end
end
