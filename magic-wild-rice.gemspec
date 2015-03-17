
require File.expand_path('../lib/magic-wild-rice/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'magic-wild-rice'
  gem.version     = MagicWildRice::VERSION::STRING.dup
  gem.date        = '2015-02-16'
  gem.summary     = "Analysis of MAGIC Wild Rice data"
  gem.description = "See summary"
  gem.authors     = ["Chris Boursnell"]
  gem.email       = 'cmb211@cam.ac.uk'
  gem.files       = `git ls-files`.split("\n")
  gem.executables = ["magic-wild-rice"]
  gem.require_paths = %w( lib )
  gem.homepage    = 'https://github.com/cboursnell/magic-wild-rice'
  gem.license     = 'MIT'

  gem.add_dependency 'trollop', '~> 2.0'
  gem.add_dependency 'bio', '~> 1.4', '>= 1.4.3'
  gem.add_dependency 'fixwhich', '~> 1.0', '>= 1.0.2'
  gem.add_dependency 'threach', '~> 0.2', '>= 0.2.0'
  gem.add_dependency 'bindeps', '~> 1.0', '>= 1.1.2'
  gem.add_dependency 'crb-blast', '~> 0.5', '>= 0.5.1'
  gem.add_dependency 'preprocessor', '~> 0.6', '0.6.1'

  gem.add_development_dependency 'rake', '~> 10.3', '>= 10.3.2'
  gem.add_development_dependency 'turn', '~> 0.9', '>= 0.9.7'
  gem.add_development_dependency 'simplecov', '~> 0.8', '>= 0.8.2'
  gem.add_development_dependency 'shoulda-context', '~> 1.2', '>= 1.2.1'
  gem.add_development_dependency 'coveralls', '~> 0.7'
end
