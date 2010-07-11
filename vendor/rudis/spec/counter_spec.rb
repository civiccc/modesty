describe Rudis::Counter do
  before :each do
    Rudis::Counter.redis.flushdb
    @c = Rudis::Counter.new('my_counter')
  end

  it "counts!" do
    @c.to_i.should == 0
    @c.should be_zero
    @c.incr.should == 1
    @c.incr.should == 2
    @c.decr.should == 1
    @c.incrby(4).should == 5
    @c.decrby(2).should == 3
    @c.incrby(-1).should == 2
  end
end
