#!/usr/bin/env ruby
#^syntax detection

# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rspec' do
  watch(%r{^spanx\.gemspec}) { "spec"}
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) { "spec" }
  watch('spec/spec_helper.rb')  { "spec" }
end

