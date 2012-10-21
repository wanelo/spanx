# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ip-blocker/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Konstantin Gredeskoul","Eric Saxby"]
  gem.email         = %w(kigster@gmail.com sax@livinginthepast.org)
  gem.description   = %q{Real time IP parsing and rate detection gem for access_log files}
  gem.summary       = %q{Real time IP parsing and rate detection gem for access_log files}
  gem.homepage      = "https://github.com/wanelo/ip-blocker"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "ip-blocker"
  gem.require_paths = %w(lib)
  gem.version       = IPBlocker::VERSION

  gem.add_dependency 'file-tail'
  gem.add_dependency 'mixlib-cli'
  gem.add_dependency 'daemons'
  gem.add_dependency 'redis'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'fakeredis'
  gem.add_development_dependency 'timecop'

  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'rb-fsevent'

end
