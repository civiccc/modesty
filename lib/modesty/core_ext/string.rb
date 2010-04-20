class String
  # casts to an integer if applicable,
  # else leaves it alone.
  def to_i?
    Integer(self)
  rescue
    self
  end
end
