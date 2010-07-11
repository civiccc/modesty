Rudis
=====

Rudis is a simple framework for implementing your favorite Redis recipes in Ruby.  There are only two concepts to Rudis:

Types
-----

A type consists of any object that responds to `put` and `get`.These are used to transparently serialize and unserialize elements of your Redis sets, lists, zsets, and hashes.  For example:

    >> s = Rudis::Set.new(:type => Rudis::JSONType)
    >> s.add [1,2,3,4] # actually adds [1,2,3,4].to_json to the set
    >> s.add {'foo' => 'bar'} # => '{foo:"bar"}' is added
    >> s.include? {'foo' => 'bar'}
    true
    >> s.to_a
    [[1,2,3,4], {'foo' => 'bar'}]

You can write your own types, too!

    class ActiveRecordType
      def initialize(model)
        @model = model
      end
      def self.put(val)
        val.id
      end
      def self.get(val)
        @model.find(val.to_i)
      end
    end

Recipes
-------

A recipe is a subclass of `Rudis::Base`.  Rudis provides two handy-dandy methods: `key` and `redis`.  `redis` is both an instance method and a class method that gives you an instance of Redis (writable, with sensible defaults).  `key` is really handy:

    class Foo < Rudis::Base
    end

    >> Foo.new('foo').key
    => "foo"
    >> Foo.new('foo').key('bar', 'baz')
    => "foo:bar:baz"
    >> Foo.key_sep = '/'
    >> Foo.new('foo').key('bar', 'baz')
    => "foo/bar/baz"
    >> Foo.key_base = ['foo', 'bar']
    >> Foo.new('zot').key('zongo')
    => "foo/bar/zot/zongo"

Enjoy!  I have lots of TODOs, including better SORT integration, more builtin types (like Marshall), and always more examples.  Checkout `examples/` for a few neat examples.
