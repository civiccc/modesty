describe Modesty, "Working with identities" do
  before :each do
    id = rand 10**10
  end

  it "can make an identity" do
    Modesty.identify! id
    Modesty.identity.should == id
  end

  it "can use a custom identifier" do
    Modesty.identify do
      id + 500
    end
    Modesty.identify!
    Modesty.identity.should == id + 500
  end
end
