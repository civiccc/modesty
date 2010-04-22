module Modesty
  module LoadMethods
    attr_writer :metrics_dir
    def metrics_dir
      @metrics_dir ||= File.join(
        Modesty.root,
        'metrics'
      )
    end
    
    def load_all_metrics!
      Dir.glob(
        File.join(self.metrics_dir, '**')
      ).each { |f| load f }
    end
  end
end
