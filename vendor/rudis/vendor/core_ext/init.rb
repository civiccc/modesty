PROJECT_DIR = File.expand_path(File.dirname(__FILE__))
$:.unshift PROJECT_DIR

Dir[File.join(PROJECT_DIR, 'lib/**')].each do |f|
  require f
end
$:.shift
