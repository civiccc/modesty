describe Rudis::ZSet do
  before :each do
    Rudis::ZSet.redis.flushdb
    @zset = Rudis::ZSet.new('my_zset',
      :type => Rudis::JSONType,
      :score_type => Rudis::TimeType
    )
  end

  it "implements the zset commands" do
    now = Time.now
    yesterday = now - 60*60*24
    tomorrow = now + 60*60*24
    @zset.should be_empty
    @zset.count.should == 0
    @zset.add([1,2,3], now)
    @zset.length.should == 1
    @zset.should_not be_empty
    @zset.first.should == [1,2,3]
    @zset.add({'four' => 4}, yesterday)
    @zset.size.should == 2
    @zset.add(['five' => 5, 'six' => 6], tomorrow)
    @zset.all.should == [
      {'four' => 4},
      [1,2,3],
      ['five' => 5, 'six' => 6]
    ]
    @zset.revrange(0..-2).should == [
      ['five' => 5, 'six' => 6],
      [1,2,3]
    ]
    @zset.range_by_score(yesterday, now).should == [
      {'four' => 4},
      [1,2,3]
    ]
    @zset.score("idontexist").should be_nil
    @zset.should_not include("idontexist")
    @zset.score({'four' => 4}).to_i.should == yesterday.to_i
  end
end
