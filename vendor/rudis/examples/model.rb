require File.join(File.dirname(__FILE__), '..', 'init')
require 'set'

class Model < Rudis::Base
  def self.attrs
    @attrs ||= {}
  end

  def self.attr(name, type)
    attrs[name] = type
  end

  def self.id_counter
    @id_counter ||= Rudis::Counter.new(key(:id_counter))
  end

  def self.inherited(klass)
    klass.key_base << klass.name
  end

  def initialize(attrs={})
    @id = options.delete(:id)
    __hash__.merge(attrs)
  end

  def id
    @id ||= self.class.id_counter.incr
  end

  def to_h
    __hash__.map_keys { |k| k.to_sym }.merge(:id => @id)
  end

  def [](k)
    __hash__[k.to_s]
  end

  def []=(k,v)
    __hash__[k.to_s] = v
  end

  def save!
    #Validate that shit, eventually
    redis.hmset(key, __hash__.to_a.flatten)
  end

  def saved?
    !@id.nil?
  end

private
  def type_for(k)
    self.class.attrs[k.to_sym]
  end

  def __hash__
    @__hash__ ||= if saved?
      Hash.new do |hsh, k|
        if self.class.attrs.include? k.to_sym
          h = redis.hgetall(key(:objects, @id).map do |k,v|
            [k, type_for(k).get(v)]
          end.to_h
          hsh.rmerge!(h)
          hsh[k]
        else
          raise ArgumentError, "Unknown attribute #{k} for #{self.inspect}"
        end
      end
    else
      {}
    end
  end
end
