require 'modesty'

describe Modesty, "Working with identities" do
  before :each do
    @id = rand 10**10
  end

  it "can make an identity" do
    Modesty.identify! @id
    Modesty.identity.should == @id
  end

  it "can identify as nil" do
    Modesty.identify! nil
    Modesty.identity.should be_nil
  end

  after :all do
    Modesty.instance_variable_set("@identity", nil)
  end
end
