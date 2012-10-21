# Spanx

Spank down IP spam.

## Installation

Add this line to your application's Gemfile:

    gem 'spanx'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install spanx

## Dependencies

Spanx uses Redis to save state and do set logic on the information it finds.

## Usage

Spanx has a single executable with several sub-commands.

### watch

This command watches an nginx log file and writes out blocked IPs to a file specified on the command line.

```bash
Usage: spanx watch [options]
    -a, --analyze                 Analyze IPs (as opposed to running `spanx analyze`
                                    in another process)
    -b, --block_file BLOCK_FILE   Output file to store NGINX block list
    -c, --config CONFIG           Path to config file (YML) (required)
    -d, --daemonize
    -g, --debug                   Log stuff
    -f, --file LOGFILE            Log file to scan continuously
    -w, --whitelist WHITELIST     File containing newline separated regular expressions to
                                    exclude log lines from blocker
    -h, --help                    Show this message
```

### analyze

Analyzes IPs found by the `watch` command. If an IP exceeds its maximum count for a time
period check (as set in the config file), the IP is written into Redis with a TTL defined by the
period check.

```bash
Usage: spanx analyze [options]
    -c, --config CONFIG              Path to config file (YML) (required)
    -d, --daemonize
    -g, --debug                      Log status to STDOUT
    -h, --help                       Show this message
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
