describe Rudis::Base do
  before :all do
    class Foo < Rudis::Base
    end
  end

  it "has a writable base key" do
    foo = Foo.new('foo_key')
    Foo.key.should == 'rudis'
    foo.key.should == 'rudis:foo_key'
    Foo.key_base = ['Foo']
    Foo.key.should == 'Foo'
    foo.key.should == 'Foo:foo_key'
  end

  it "has a writable key separator" do
    Foo.key_sep = '/'
    Foo.key_base = ['Foo']
    foo = Foo.new(:a)
    foo.key(:b, "c:d:e").should == 'Foo/a/b/c:d:e'
  end
end
