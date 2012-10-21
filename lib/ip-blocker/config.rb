require "yaml"
require 'ip-blocker/helper/exit'

module IPBlocker
  class Config < Hash
    include IPBlocker::Helper::Exit

    attr_accessor :filename

    def initialize(filename)
      super
      @filename = filename
      load_file
      self
    end

    private

    def load_file
      begin
        self.merge! ::YAML.load_file(filename)
      rescue Errno::ENOENT
        error_exit_with_msg "Unable to find config_file at #{filename}"
      end
    end
  end
end
