class Class
  def soft_alias(new, target)
    class_eval <<-code
      def #{new}(*args, &blk)
        #{target}(*args, &blk)
      end
    code
  end
end
