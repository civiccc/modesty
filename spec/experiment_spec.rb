require 'modesty'

describe Modesty::Experiment, "creating an experiment" do
  before :all do
    Modesty.metrics = {}
    Modesty.new_metric :foo do |m|
      m.description "Foo"
      m.submetric :bar do |m|
        m.description "Bar"
      end
    end

    Modesty.new_metric :baz do |m|
      m.description "Baz"
    end
  end

  it "can create an experiment with a block" do
    e = Modesty.new_experiment(:creation_page) do |m|
      m.description "Three versions of the creation page"
      m.alternatives :heavyweight, :middleweight, :lightweight
      m.metrics :foo/:bar, :baz
    end 

    Modesty.experiments.should include :creation_page
    Modesty.experiments[:creation_page].should == e

    e.metrics.should include Modesty.metrics[:foo/:bar]
    e.metrics.should include Modesty.metrics[:baz]
    e.alternatives.should == [:heavyweight, :middleweight, :lightweight]
    e.description.should == "Three versions of the creation page"
  end

  it "auto-creates metrics" do
    Modesty.metrics.should include :foo/:bar/:creation_page/:heavyweight
    Modesty.metrics.should include :foo/:bar/:creation_page/:middleweight
    Modesty.metrics.should include :foo/:bar/:creation_page/:lightweight
    Modesty.metrics.should include :baz/:creation_page/:heavyweight
    Modesty.metrics.should include :baz/:creation_page/:middleweight
    Modesty.metrics.should include :baz/:creation_page/:lightweight
  end
end

describe "A/B testing" do
  before :all do
    Modesty.identify :default
    Modesty.set_store :mock
  end

  it "Selects evenly between alternatives" do
    (0..(3*8-1)).each do |i|
      Modesty.identify! i
      Modesty.ab_test :creation_page/:lightweight do
        Modesty.track! :baz/:creation_page/:lightweight
        Modesty.metrics[:baz/:creation_page/:lightweight].values.should == 1+i/3
      end
      Modesty.ab_test :creation_page/:middleweight do
        Modesty.track! :baz/:creation_page/:middleweight
        Modesty.metrics[:baz/:creation_page/:middleweight].values.should == 1+i/3
      end
      Modesty.ab_test :creation_page/:heavyweight do
        Modesty.track! :baz/:creation_page/:heavyweight
        Modesty.metrics[:baz/:creation_page/:heavyweight].values.should == 1+i/3
      end
      Modesty.metrics[:baz].values.should == 1+i
    end
  end

  it "tracks the number of users in each experimental group" do
    e = Modesty.experiments[:creation_page]
    e.users.should == 3*8
    e.users(:lightweight).should == 8
    e.users(:middleweight).should == 8
    e.users(:heavyweight).should == 8
  end
end
