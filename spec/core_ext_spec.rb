require 'modesty'

describe Symbol do
  [
    :abc,
    :abc=,
    :a/:bc/:def,
    :/,
    :"////",
    :':',
    :"http://www.google.com/",
  ].each do |sym|
    it "eval(:\"#{sym}\".inspect) == :\"#{sym}\"" do
      eval(sym.inspect).should == sym
    end
  end
end
