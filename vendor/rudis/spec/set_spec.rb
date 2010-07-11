describe Rudis::Set do
  before :each do
    @key = (1..rand(5)).map { Time.now.hash.to_s }
    @set = Rudis::Set.new(@key)
  end

  before :each do
    Rudis::Set.redis.flushdb
  end

  it "implements the set commands" do
    @set.key.should == "rudis:#{@key.join(':')}"
    @set.card.should == 0
    @set.add "foo"
    @set.size.should == 1
    @set << "bar"
    @set.count.should == 2
    @set.delete "foo"
    @set.size.should == 1
    @set.to_a.should == ["bar"]
    @set.rand.should == "bar"
    @set.pop.should == "bar"
    @set.to_a.should == []
    @set.pop.should be_nil
  end

end
