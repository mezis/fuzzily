# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fuzzily/version'

Gem::Specification.new do |gem|
  gem.name          = 'fuzzily'
  gem.version       = Fuzzily::VERSION
  gem.authors       = ['Julien Letessier']
  gem.email         = ['julien.letessier@gmail.com']
  gem.description   = %q{Fast fuzzy string matching for rails}
  gem.summary       = %q{A fast, trigram-based, database-backed fuzzy string search/match engine for Rails.}
  gem.homepage      = 'http://github.com/martijncasteel/fuzzily'
  gem.license       = 'MIT'

  gem.add_runtime_dependency 'activerecord'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'appraisal'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'pry-nav'
  gem.add_development_dependency 'sqlite3'
  gem.add_development_dependency 'pg'
  gem.add_development_dependency 'mysql2'
  gem.add_development_dependency 'coveralls'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
end
