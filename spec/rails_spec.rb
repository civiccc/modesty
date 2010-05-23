describe "bootstrap" do
  before :all do
    Modesty.data.flushdb
    Modesty.metrics.clear
    Modesty.experiments.clear

    unless defined? Rails
      class Rails
        def self.root
          File.join(
            File.expand_path(File.dirname(__FILE__)),
            '../test/myapp'
          )
        end

        def self.configuration
          self
        end

        def self.env
          'test'
        end

        def self.after_initialize
          yield
        end
      end
    end

    require 'modesty/frameworks/rails'
  end

  it "bootstraps Redis" do
    Modesty.data.store.should be_an_instance_of Redis
    Modesty.data.store.client.port.should == 6379
    Modesty.data.store.client.host.should == 'localhost'
  end

  it "loads metrics" do
    Modesty.metrics.keys.should include :baked_goods
  end

  it "loads experiments" do
    Modesty.experiments.keys.should include :cookbook
  end
end
