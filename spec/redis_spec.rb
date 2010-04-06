describe "Real Redis" do
  it "can connect to redis" do
    lambda { Modesty.set_store :redis }.should_not raise_error
    Modesty.data.should be_an_instance_of Redis
    lambda { Modesty.data.flushdb }.should_not raise_error
  end

  it "can track metrics in real redis" do
    lambda do
      (1..100).each do |i|
        Modesty.track! :foo, 2
        Modesty.metrics[:foo].values.should == i*2
      end
    end.should_not raise_error
  end

  after :all do
    Modesty.set_store :mock
  end
end
