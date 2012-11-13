require 'yaml'
require 'pause'
require 'spanx/helper/exit'

module Spanx
  class Config < Hash
    include Spanx::Helper::Exit

    attr_accessor :filename

    def initialize(filename)
      super
      @filename = filename
      load_file

      Pause.configure do |pause|
        pause.redis_host = self[:redis][:host]
        pause.redis_port = self[:redis][:port]
        pause.redis_db   = self[:redis][:database]

        pause.resolution = self[:collector][:resolution]
        pause.history    = self[:collector][:history]
      end

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
