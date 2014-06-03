require 'redis'
require 'pause'
require 'spanx/version'
require 'spanx/helper'
require 'spanx/logger'
require 'spanx/config'
require 'spanx/usage'

require 'spanx/ip_checker'

require 'spanx/cli'
require 'spanx/notifier/base'
require 'spanx/notifier/campfire'
require 'spanx/notifier/audit_log'
require 'spanx/notifier/email'
require 'spanx/notifier/slack'

require 'spanx/actor/log_reader'
require 'spanx/actor/collector'
require 'spanx/actor/analyzer'
require 'spanx/actor/writer'
require 'spanx/whitelist'

require 'spanx/runner'

module Spanx
end

class String
  def constantize
    camel_cased_word = self
    unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ camel_cased_word
      raise NameError, "#{camel_cased_word.inspect} is not a valid constant name!"
    end

    Object.module_eval("::#{$1}", __FILE__, __LINE__)
  end
end

