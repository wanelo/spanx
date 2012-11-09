require 'yaml'
require 'spanx/helper/exit'

module Spanx
  class Config < Hash
    include Spanx::Helper::Exit

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
