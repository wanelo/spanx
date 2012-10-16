# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ip-blocker/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Konstantin Gredeskoul","Eric Saxby"]
  gem.email         = ["kigster@gmail.com", "sax@livinginthepast.org"]
  gem.description   = %q{Real time IP parsing and rate detection gem for access_log files}
  gem.summary       = %q{Real time IP parsing and rate detection gem for access_log files}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "ip-blocker"
  gem.require_paths = ["lib"]
  gem.version       = IPBlocker::VERSION

  gem.add_dependency "file-tail"
end
