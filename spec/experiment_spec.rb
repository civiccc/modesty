require 'modesty'

describe Modesty::Experiment, "creating an experiment" do
  before :all do
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
    Modesty.new_experiment(:creation_page) do |m|
      m.description "Three versions of the creation page"
      m.alternatives :heavyweight, :middleweight, :lightweight
      m.metrics :foo/:bar, :baz
    end
  end
end
