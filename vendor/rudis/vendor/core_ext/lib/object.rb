class Object
  def metaclass
    class << self
      self
    end
  end

  def meta_eval(&blk)
    self.metaclass.class_eval(&blk)
  end
end
