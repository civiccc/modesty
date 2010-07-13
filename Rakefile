require 'rake'
require 'spec/rake/spectask'

Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.ruby_opts = ['-Ilib']
  t.spec_opts = ['-O spec/spec.opts']
end
