module Modesty
  module LoadMethods
    attr_writer :experiments_dir
    def experiments_dir
      @experiments_dir ||= File.join(Modesty.root, 'experiments')
    end

    def load_all_experiments!
      Dir.glob(
        File.join(self.experiments_dir, '*.rb')
      ).each { |f| load f }
    end
  end
end
