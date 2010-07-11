describe Rudis::Hash do
  before :each do
    Rudis::Hash.redis.flushdb
    @hash = Rudis::Hash.new('myhash',
      :key_type => Rudis::SymbolType,
      :type => Rudis::IntegerType
    )
  end

  it "implements the hash commands" do
    @hash.should be_empty
    @hash.length.should == 0
    @hash[:foo] = 3
    @hash.should_not be_empty
    @hash[:foo].should == 3
    @hash.all.should == {:foo => 3}
    @hash[:bar] = 4
    @hash.keys.to_set.should == Set.new([:foo, :bar])
    @hash.values.sort.should == [3,4]
    @hash.count.should == 2
    @hash.to_h.should == {:foo => 3, :bar => 4}
    @hash[:foo] = 5
    @hash[:foo].should == 5
    @hash.size.should == 2
    @hash.slice(:foo).should == {:foo => 5}
    @hash.merge!(:bar => 6, :baz => 7)
    @hash.count.should == 3
    @hash.to_h.should == {:foo => 5, :bar => 6, :baz => 7}
    @hash.get(:baz).should == 7
    @hash.get(:idontexist).should be_nil
  end
end
