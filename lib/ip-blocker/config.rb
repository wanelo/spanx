require "yaml"
module IPBlocker
  class Config < Hash
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
        $stderr.puts("Unable to find config_file at #{filename}")
        exit(1)
      end
    end
  end
end
