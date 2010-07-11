class Graph < Rudis::Base
  def add(follower, followee)
    redis.multi do
      _followers_of(followee) << follower
      _follows(follower) << followee
    end
  end

  def delete(follower, followee)
    redis.multi do
      _followers_of(followee).delete(follower)
      _follows(follower).delete(followee)
    end
  end

  def followers_of(id)
    _followers_of(id).to_a
  end

  def follows(id)
    _follows(id).to_a
  end

  def follows?(follower, followee)
    _followers_of(followee).include? follower
  end

private
  def _follows(id)
    Rudis::Set.new(key(id, :follows), :type => type)
  end

  def _followers_of(id)
    Rudis::Set.new(key(id, :followers), :type => type)
  end
end

g = Graph.new('my_graph', :type => Rudis::IntegerType)
g.add(1, 2)
g.add(1, 3)
g.follows(1).to_a # => [2,3]
g.add(2, 3)
g.followers_of(3) # => [1,2]
g.delete(2, 3)
g.followers_of(3) # => [1]
