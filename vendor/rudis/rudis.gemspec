spec = Gem::Specification.new do |s|
  s.name = 'rudis'
  s.version = '0.1'
  s.add_dependency 'redis', '>= 2.0'

  s.summary = 'An extensible OO redis client for ruby'
  s.description = <<-desc
    Rudis wraps redis-rb in objects that keep track of their own
    redis instances and keys.
  desc

  s.files = (
    Dir['lib/**/*.rb'] +
    Dir['spec/**/*.rb'] +
    Dir['vendor/**/*.rb'] +
    %w(init.rb Rakefile README.md LICENSE)
  )

  s.author = 'Jay Adkisson'
  s.email = 'j4yferd@gmail.com'
  s.homepage = 'http://github.com/jayferd/rudis'

  s.license = 'MIT'

  s.has_rdoc = false

  s.required_ruby_version = '>= 1.8.7'
end
