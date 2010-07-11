class File
  def self.write(filename, content)
    open(filename, "w") do |f|
      f.write(content)
    end
  end

  def self.append(filename, content)
    open(filename, "a") do |f|
      f << content
    end
  end

  def self.add_line(filename, content)
    self.append(filename, content.chomp + $/)
  end
end
