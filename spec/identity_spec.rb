describe Modesty, "Working with identities" do
  before :each do
    @id = rand 10**10
    Modesty.identify :default
  end

  it "can make an identity" do
    Modesty.identify! @id
    Modesty.identity.should == @id
  end

  it "can use a custom identifier" do
    Modesty.identify do
      @id + 500
    end
    Modesty.identify!
    Modesty.identity.should == @id + 500
  end

  it "can use a custom identifier with args" do
    Modesty.identify do |number|
      number + 600
    end

    lambda { Modesty.identify! }.should raise_error(
      ArgumentError, "Wrong number of arguments (0 for 1)"
    )

    lambda { Modesty.identify! @id}.should_not raise_error
    Modesty.identity.should == @id + 600
  end

  it "can use a custom identifier with starred args" do
    Modesty.identify do |a, *b|
      a + b.last
    end

    Modesty.identify! @id, 5, 6, 7, 8, 9
    Modesty.identity.should == @id + 9
  end
end
