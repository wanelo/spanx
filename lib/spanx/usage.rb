module Spanx
  module Usage
    def self.print
      $stdout.puts %q{Usage: spanx command [options]
  watch   -- Watch a server log file and write out a block list file
  analyze -- Analyze IP traffic and save blocked IPs into Redis
}
    end
  end
end
