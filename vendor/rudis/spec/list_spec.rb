describe Rudis::List do
  before :each do
    Rudis::List.redis.flushdb
    @list = Rudis::List.new('mylist', :type => Rudis::IntegerType)
  end

  it "implements the list commands" do
    @list.size.should == 0
    @list << 1
    @list.to_a.should == [1]
    @list.unshift 2
    @list.count.should == 2
    @list.all.should == [2,1]
    @list.lpush 3
    @list.shift.should == 3
    @list.pop.should == 1
    @list.lpop.should == 2
    @list.length.should == 0
    @list.rpop.should be_nil
    @list.should be_empty
    @list.to_a.should == []
  end
end
