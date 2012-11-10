module Spanx
  USAGE = %q{Usage: spanx command [options]
  watch   -- Watch a server log file and write out a block list file
  analyze -- Analyze IP traffic and save blocked IPs into Redis
  flush   -- Remove all IP blocks and delete previous tracking of that IP
  disable -- Disable IP blocking
  enable  -- Enable IP blocking if disabled
}
end
