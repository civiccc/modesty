require 'modesty'

describe "bootstrap" do
  before :all do
    class Rails
      def self.root
        File.join(
          File.expand_path(File.dirname(__FILE__)),
          '../test/myapp'
        )
      end
      def self.after_initialize
        yield
      end
    end
  end

  it "can bootstrap" do
    lambda { require 'modesty/frameworks/rails.rb' }.should_not raise_error
  end

  it "bootstraps Redis" do
    Modesty.data.class.name.should == 'Redis'
    Modesty.data.instance_variable_get("@port").should == 6379
    Modesty.data.instance_variable_get("@host").should == 'localhost'
  end

  it "loads metrics" do
    Modesty.metrics.should include :baked_goods
  end

  it "loads experiments" do
    Modesty.experiments.should include :cookbook
  end
end
