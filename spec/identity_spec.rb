describe Modesty, "Working with identities" do
  it "can make an identity" do
    id = rand(10**10)
    Modesty.identify id
    Modesty.identity.should == id
  end
end
