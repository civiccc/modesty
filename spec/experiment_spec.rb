require 'modesty'

describe Modesty::Experiment, "creating an experiment" do
  before :each do
    Modesty.metrics.clear
    Modesty.experiments.clear
    Modesty.new_metric :foo do |m|
      m.description "Foo"
      m.submetric :bar do |m|
        m.description "Bar"
      end
    end

    Modesty.new_metric :baz do |m|
      m.description "Baz"
    end

    @e = Modesty.new_experiment(:creation_page) do |m|
      m.description "Three versions of the creation page"
      m.alternatives :heavyweight, :lightweight
      m.metrics :foo/:bar, :baz
    end 

    @f = Modesty.new_experiment :ab_test do |e|
      e.description "only two groups"
      e.metrics :baz
    end
  end

  it "can create an experiment with a block" do
    Modesty.experiments.should include :creation_page
    Modesty.experiments[:creation_page].should == @e

    @e.metrics.should include Modesty.metrics[:foo/:bar]
    @e.metrics.should include Modesty.metrics[:baz]
    @e.alternatives.should == [:control, :heavyweight, :lightweight]
    @e.description.should == "Three versions of the creation page"
  end

  it "uses [:control, :experiment] as the default experiment groups" do
    @f.alternatives.should == [:control, :experiment]
  end

  it "auto-creates metrics" do
    Modesty.metrics.keys.should include :foo/:bar/:creation_page/:control
    Modesty.metrics.keys.should include :foo/:bar/:creation_page/:heavyweight
    Modesty.metrics.keys.should include :foo/:bar/:creation_page/:lightweight
    Modesty.metrics.keys.should include :baz/:creation_page/:control
    Modesty.metrics.keys.should include :baz/:creation_page/:heavyweight
    Modesty.metrics.keys.should include :baz/:creation_page/:lightweight

    Modesty.metrics.keys.should include :baz/:ab_test/:control
    Modesty.metrics.keys.should include :baz/:ab_test/:experiment
  end

  it "grabs metrics nicely with e.metrics(alt)" do
    @e.alternatives.each do |alt|
      @e.metrics(alt).should == {
        :foo/:bar => Modesty.metrics[:foo/:bar/:creation_page/alt],
        :baz      => Modesty.metrics[:baz/:creation_page/alt],
      }
    end

    lambda do
      @e.metrics(:i_dont_exist)
    end.should raise_error(Modesty::Experiment::Error)
  end
end

describe "A/B testing" do
  before :all do
    Modesty.set_store :redis, :mock => true
  end

  it "Selects evenly between alternatives" do
    (0..(3*100-1)).each do |i|
      Modesty.identify! i
      Modesty.experiment :creation_page do |exp|
        [:control, :lightweight, :heavyweight].each do |alt|
          exp.group alt do
            Modesty.track! :baz
          end
        end
      end
      Modesty.metrics[:baz].count.should == 1+i
    end
  end

  it "assigns guests to :control" do
    Modesty.identify! nil
    Modesty.group(:ab_test).should == :control
    Modesty.group?(:ab_test/:control).should == true

    Modesty.identify! 200
  end

  it "can use a passed-in identity" do
    leet = Modesty.experiment :ab_test, :on => 1337 do |exp|
      [:control, :experiment].each do |alt|
        exp.group alt do
          Modesty.identity
        end
      end
    end

    leet.should == 1337
  end

  it "can used a passed-in nil identity" do
    test = Modesty.experiment :ab_test, :on => nil do |exp|
      exp.group :control do
        Modesty.identity
      end
      exp.group :experiment do
        "fail"
      end
    end

    test.should be_nil
  end

  it "tracks the users in each experimental group" do
    e = Modesty.experiments[:creation_page]
    lambda { e.users }.should_not raise_error
    u = e.users
    u.should be_a Array
    (1..(3*100-1)).each do |i|
      u.should include i
    end
  end

  it "tracks the number of users in each experimental group" do
    e = Modesty.experiments[:creation_page]
    e.num_users.should == 3*100
    [:lightweight, :control, :heavyweight].each do |alt|
      e.num_users(alt).should be_close 3*100/4, 2 + 3*100/6
    end
  end

  it "uses cached alternative" do
    class Modesty::Experiment
      alias old_generate generate_alternative
      def generate_alternative
        raise RuntimeError
      end
    end
    # should ask Redis for the correct alternative
    # instead of running generate_alternative
    lambda do
      (0..(3*100-1)).each do |i|
        Modesty.identify! i
        Modesty.group :creation_page
      end
    end.should_not raise_error
    class Modesty::Experiment
      alias generate_alternative old_generate
    end
  end

  it "tracks the experiment group if you've hit the experiment" do
    Modesty.identify! 500 #not in the experiment group yet
    [:control, :lightweight, :heavyweight].each do |alt|
      lambda do
        Modesty.track! :baz
      end.should_not change(Modesty.metrics[:baz/:creation_page/alt], :count)
    end

    alt = Modesty.group :creation_page
    lambda do
      Modesty.track! :baz, 5
    end.should change(Modesty.metrics[:baz/:creation_page/alt], :count).by(5)
  end

  it "allows for manually setting your experiment group" do
    Modesty.identify! 50
    e = Modesty.experiments[:creation_page]
    2.times do
      e.alternatives.each do |alt|
        lambda do
          e.chooses alt
          e.group.should == alt
        end.should_not change(e, :num_users)
      end
    end
  end
end

describe "Datastore failing" do
  before :each do
    Modesty.data.flushdb
    Modesty.experiments.clear
    Modesty.metrics.clear

    Modesty.new_metric :foo

    Modesty.new_experiment :my_exp do |e|
      e.metric :foo
    end

    Modesty.data.stub!(:get_cached_alternative).and_raise(
      Modesty::Datastore::ConnectionError
    )

    Modesty.data.stub!(:register!).and_raise(
      Modesty::Datastore::ConnectionError
    )
  end

  it "fails gracefully for choose_group" do
    Modesty.identify! 9876
    first_group = second_group = nil
    lambda do
      first_group = Modesty.group :my_exp
    end.should_not raise_error(Modesty::Datastore::ConnectionError)

    lambda do
      second_group = Modesty.group :my_exp
    end.should_not raise_error(Modesty::Datastore::ConnectionError)

    #should be consistent
    first_group.should == second_group
  end
end
