Gem::Specification.new do |s|
  s.name          = "mongoid-ordering"
  s.version       = "0.1.2"
  s.platform      = Gem::Platform::RUBY
  s.author        = "Douwe Maan"
  s.email         = "douwe@selenight.nl"
  s.homepage      = "https://github.com/DouweM/mongoid-ordering"
  s.summary       = "Easy ordering of your Mongoid documents."
  s.description   = "mongoid-ordering makes it easy to keep your Mongoid documents in order."
  s.license       = "MIT"

  s.files         = Dir.glob("lib/**/*") + %w(LICENSE README.md Rakefile Gemfile)
  s.test_files    = Dir.glob("spec/**/*")
  s.require_path  = "lib"

  s.add_runtime_dependency "mongoid", "~> 3.0"
  s.add_runtime_dependency "mongoid-siblings", "~> 0.1.0"
  
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
end
