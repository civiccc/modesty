require 'rubygems'
require 'rake'
require 'spec/rake/spectask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "modesty"
    gem.summary = %Q{Modesty is a really simple metrics and a/b testing framework that doesn't really do all that much.}
    gem.description = %Q{Modesty is a really simple metrics and a/b testing framework that doesn't really do all that much. It was inspired by assaf's Vanity (github.com/assaf/vanity).}
    gem.email = "jay@causes.com"
    gem.homepage = "http://github.com/causes/modesty"
    gem.authors = ["Kevin Ball"]
    gem.add_development_dependency "rspec"
    gem.add_runtime_dependency "redis"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.ruby_opts = ['-Ilib']
  t.spec_opts = ['-O spec/spec.opts']
end
