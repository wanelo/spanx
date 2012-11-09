# -*- encoding: utf-8 -*-
require File.expand_path('../lib/spanx/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Konstantin Gredeskoul","Eric Saxby"]
  gem.email         = %w(kigster@gmail.com sax@livinginthepast.org)
  gem.description   = %q{Real time IP parsing and rate detection gem for access_log files}
  gem.summary       = %q{Real time IP parsing and rate detection gem for access_log files}
  gem.homepage      = "https://github.com/wanelo/spanx"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "spanx"
  gem.require_paths = %w(lib)
  gem.version       = Spanx::VERSION

  gem.add_dependency 'file-tail'
  gem.add_dependency 'mixlib-cli'
  gem.add_dependency 'daemons'
  gem.add_dependency 'redis'
  gem.add_dependency 'mash'
  gem.add_dependency 'tinder'
  gem.add_dependency 'mail', '~> 2.4.4'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'fakeredis'
  gem.add_development_dependency 'timecop'

  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'rb-fsevent'

end
