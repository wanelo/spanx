module IPBlocker
  module Actor
    class Writer
      include IPBlocker::Helper
      attr_accessor :config, :adapter

      def initialize config, adapter = nil
        @config = config
        @adapter = adapter || IPBlocker::Redis::Adapter.new(config)
        @block_file = config[:block_file]
      end

      def run
        Thread.new do
          Thread.current[:name] = "writer"
          loop do
            self.write
            sleep config[:writer][:write_interval]
          end
        end
      end

      def write
        ips = adapter.blocked_ips
        logging "writing out #{ips.size} IP rules into #{@block_file}" do
          File.open(@block_file, "w") do |file|
            ips.sort.each do |ip|
              file.puts("deny #{ip};")
            end
          end
        end
      end
    end
  end
end
