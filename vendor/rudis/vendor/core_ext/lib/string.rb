class String
  def match?(regex)
    self.match(regex) ? true : false
  end

  def squish!
    self.strip!.gsub!(/\s+/,' ')
    self
  end

  def squish
    self.dup.squish!
  end

  def lines
    self.split($/)
  end

  def map_parts(delim=$/, &blk)
    self.split(delim).map(&blk).join(delim)
  end

  def unchomp!(ch=$/)
    self.chomp!(ch)
    self << ch
    self
  end

  def unchomp(ch)
    self.dup.unchomp!(ch)
  end
end
