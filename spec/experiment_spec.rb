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
