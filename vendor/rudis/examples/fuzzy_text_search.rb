require 'rubygems'
require 'text'

# Fuzzy search with the double metaphone algorithm, from
# http://playnice.ly/blog/2010/05/05/a-fast-fuzzy-full-text-index-using-redis/
class FuzzyTextSearch < Rudis::Base
  def add(word)
    redis.multi do
      _all << word
      Text::Metaphone.double_metaphone(word).each do |m|
        _index(m) << word unless m.nil?
      end
    end
  end

  def search(word)
    r = Set.new
    Text::Metaphone.double_metaphone(word).each do |m|
      r.merge(_index(m).to_a) unless m.nil?
    end
  end

  def delete(word)
    redis.multi do
      _all.delete(word)
      Text::Metaphone.double_metaphone(word).each do |m|
        _index(m).delete(word) unless m.nil?
      end
    end
  end

  def all
    _all.to_a
  end

private
  def _all
    Rudis::Set.new(key, :type => Rudis::StringType)
  end

  def _index(metaphone)
    Rudis::Set.new(key(metaphone), :type => Rudis::StringType)
  end
end

f = FuzzyTextSearch.new('my_fuzzy_text_search')
f.add('chunky bacon')
f.add('chunkie bakin')
f.search('chonk bkn') # => ['chunky bacon', 'chunkie bakin']
